from fastapi import APIRouter, Depends, HTTPException
from fastapi.responses import JSONResponse
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import current_user, optional_user
from app.core.security import (
    create_access_token, create_refresh_token, decode_token, hash_password, verify_password,
)
from app.db import get_db
from app.models import Category, ProProfile, User
from app.schemas import (
    LoginIn, MeOut, MeUpdate, OtpSendIn, OtpVerifyIn, PasswordChange, RefreshIn, RegisterIn,
    TokenOut, me_out,
)
from app.services import cache, otp
from app.services.ledger import wallet_of

router = APIRouter(prefix="/auth", tags=["auth"])


def _tokens(user: User) -> TokenOut:
    return TokenOut(
        access_token=create_access_token(user.id, user.role),
        refresh_token=create_refresh_token(user.id),
        user=me_out(user),
    )


@router.post("/register", response_model=TokenOut, status_code=201)
def register(payload: RegisterIn, db: Session = Depends(get_db)):
    if not payload.email and not payload.phone:
        raise HTTPException(422, "E-mail ou téléphone requis")
    email = payload.email.lower() if payload.email else None
    clash = db.scalars(select(User).where(or_(
        User.email == email if email else False,
        User.phone == payload.phone if payload.phone else False,
    ))).first()
    if clash:
        raise HTTPException(409, "Un compte existe déjà avec cet e-mail ou ce téléphone")
    user = User(name=payload.name, email=email, phone=payload.phone,
                password_hash=hash_password(payload.password), role=payload.role,
                city=payload.city)
    db.add(user)
    db.flush()
    if payload.role == "pro":
        cat = None
        if payload.category:
            cat = db.scalars(select(Category).where(Category.name == payload.category)).first()
        db.add(ProProfile(user_id=user.id, job=payload.job or "Professionnel",
                          category_id=cat.id if cat else None))
    wallet_of(db, user.id)
    db.commit()
    db.refresh(user)
    return _tokens(user)


@router.post("/login", response_model=TokenOut,
             responses={401: {"description": "Identifiants invalides ou code 2FA requis"}})
def login(payload: LoginIn, db: Session = Depends(get_db)):
    ident = payload.login.strip().lower()
    user = db.scalars(select(User).where(or_(User.email == ident, User.phone == payload.login.strip()))).first()
    if not user or not verify_password(payload.password, user.password_hash):
        raise HTTPException(401, "Identifiants invalides")
    if not user.is_active:
        raise HTTPException(403, "Compte suspendu — contactez le support")
    if user.two_fa_enabled:
        if not payload.otp:
            code = otp.issue(db, user.id, "2fa")
            db.commit()
            body = {"detail": "Code 2FA requis", "code": "2fa_required"}
            if settings.otp_dev_echo:
                body["dev_code"] = code
            return JSONResponse(status_code=401, content=body)
        otp.consume(db, user.id, "2fa", payload.otp)
        db.commit()
    return _tokens(user)


@router.post("/refresh", response_model=TokenOut)
def refresh(payload: RefreshIn, db: Session = Depends(get_db)):
    data = decode_token(payload.refresh_token, expected_type="refresh")
    user = db.get(User, data["sub"]) if data else None
    if not user or not user.is_active:
        raise HTTPException(401, "Jeton de rafraîchissement invalide")
    return _tokens(user)


@router.post("/otp/send")
def otp_send(payload: OtpSendIn, db: Session = Depends(get_db),
             user: User | None = Depends(optional_user)):
    """Envoie un code à 6 chiffres. `2fa`/`withdraw` exigent d'être connecté."""
    if payload.purpose in ("2fa", "withdraw"):
        if not user:
            raise HTTPException(401, "Authentification requise")
        target = user.id
    else:
        target = payload.target.strip()
    if not cache.rate_limit(f"otp:{target}", 5, 600):
        raise HTTPException(429, "Trop de demandes de code : réessayez dans quelques minutes")
    code = otp.issue(db, target, payload.purpose)
    db.commit()
    out = {"sent": True, "channel": "sms", "expires_in_minutes": settings.otp_ttl_minutes}
    if settings.otp_dev_echo:
        out["dev_code"] = code
    return out


@router.post("/otp/verify")
def otp_verify(payload: OtpVerifyIn, db: Session = Depends(get_db),
               user: User | None = Depends(optional_user)):
    target = user.id if payload.purpose in ("2fa", "withdraw") and user else payload.target.strip()
    otp.consume(db, target, payload.purpose, payload.code)
    if payload.purpose == "verify_phone" and user and user.phone == target:
        user.phone_verified = True
    db.commit()
    return {"verified": True}


@router.post("/otp/login", response_model=TokenOut)
def otp_login(payload: OtpVerifyIn, db: Session = Depends(get_db)):
    """Connexion sans mot de passe par SMS (purpose=login)."""
    otp.consume(db, payload.target.strip(), "login", payload.code)
    user = db.scalars(select(User).where(User.phone == payload.target.strip())).first()
    if not user or not user.is_active:
        raise HTTPException(404, "Aucun compte actif pour ce numéro")
    user.phone_verified = True
    db.commit()
    return _tokens(user)


# --------------------------------------------------------------------- compte

@router.get("/me", response_model=MeOut)
def me(user: User = Depends(current_user)):
    return me_out(user)


@router.patch("/me", response_model=MeOut)
def update_me(payload: MeUpdate, db: Session = Depends(get_db), user: User = Depends(current_user)):
    for k, v in payload.model_dump(exclude_unset=True).items():
        if k == "notification_prefs":
            v = {**(user.notification_prefs or {}), **v}
        setattr(user, k, v)
    db.commit()
    db.refresh(user)
    return me_out(user)


@router.post("/password")
def change_password(payload: PasswordChange, db: Session = Depends(get_db),
                    user: User = Depends(current_user)):
    if not verify_password(payload.current_password, user.password_hash):
        raise HTTPException(400, "Mot de passe actuel incorrect")
    user.password_hash = hash_password(payload.new_password)
    db.commit()
    return {"changed": True}


@router.post("/2fa/enable")
def enable_2fa(payload: OtpVerifyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Active la 2FA après vérification d'un code (purpose=2fa)."""
    otp.consume(db, user.id, "2fa", payload.code)
    user.two_fa_enabled = True
    db.commit()
    return {"two_fa_enabled": True}


@router.post("/2fa/disable")
def disable_2fa(payload: OtpVerifyIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    otp.consume(db, user.id, "2fa", payload.code)
    user.two_fa_enabled = False
    db.commit()
    return {"two_fa_enabled": False}
