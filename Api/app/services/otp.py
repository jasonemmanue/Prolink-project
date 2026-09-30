import hashlib
import logging
from datetime import timedelta

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.security import generate_otp
from app.db import utcnow
from app.models import OtpCode

log = logging.getLogger("prolink.otp")


def _h(code: str) -> str:
    return hashlib.sha256(code.encode()).hexdigest()


def issue(db: Session, target: str, purpose: str) -> str:
    code = generate_otp()
    db.add(OtpCode(target=target, purpose=purpose, code_hash=_h(code),
                   expires_at=utcnow() + timedelta(minutes=settings.otp_ttl_minutes)))
    # Production : envoi SMS via l'opérateur (Orange/MTN) ou un agrégateur.
    log.info("OTP %s pour %s : %s", purpose, target, code if settings.otp_dev_echo else "******")
    return code


def consume(db: Session, target: str, purpose: str, code: str | None) -> None:
    if not code:
        raise HTTPException(400, "Code de vérification requis")
    row = db.scalars(
        select(OtpCode)
        .where(OtpCode.target == target, OtpCode.purpose == purpose, OtpCode.used.is_(False),
               OtpCode.expires_at > utcnow())
        .order_by(OtpCode.created_at.desc())
    ).first()
    if not row or row.code_hash != _h(code.strip()):
        raise HTTPException(400, "Code invalide ou expiré")
    row.used = True
