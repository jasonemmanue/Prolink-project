from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import Page, current_user, optional_user, require_pro
from app.db import get_db, utcnow
from app.models import Follow, Live, LiveTicket, User
from app.schemas import LiveEndIn, LiveIn, LiveOut, LiveUpdate, TipIn, live_out
from app.services import ledger, livekit
from app.services.notify import notify, notify_many
from app.services.platform import commission

router = APIRouter(prefix="/lives", tags=["lives"])


def _live(db: Session, lid: str) -> Live:
    lv = db.get(Live, lid)
    if not lv:
        raise HTTPException(404, "Live introuvable")
    return lv


def _own(db: Session, lid: str, user: User) -> Live:
    lv = _live(db, lid)
    if lv.pro_id != user.id:
        raise HTTPException(403, "Ce live ne vous appartient pas")
    return lv


def _has_ticket(db: Session, lid: str, uid: str, kind: str = "live") -> bool:
    return db.scalars(select(LiveTicket.id).where(LiveTicket.live_id == lid, LiveTicket.user_id == uid,
                                                  LiveTicket.kind == kind)).first() is not None


def has_access(db: Session, lv: Live, user: User | None) -> bool:
    if not user:
        return lv.mode in ("free", "tips")
    if user.id == lv.pro_id or user.role == "admin":
        return True
    if lv.status == "ended":
        if lv.replay_policy == "free":
            return True
        if lv.replay_policy == "paid":
            return _has_ticket(db, lv.id, user.id, "replay") or _has_ticket(db, lv.id, user.id)
        return False
    if lv.mode == "paid":
        return _has_ticket(db, lv.id, user.id)
    if lv.mode == "followers":
        return db.scalars(select(Follow.id).where(Follow.follower_id == user.id,
                                                  Follow.pro_id == lv.pro_id)).first() is not None
    return True


@router.get("", response_model=list[LiveOut])
def list_lives(status: str | None = Query(None, description="scheduled,live,ended"),
               pro_id: str | None = None, page: Page = Depends(), db: Session = Depends(get_db),
               user: User | None = Depends(optional_user)):
    stmt = select(Live).where(Live.status != "cut")
    if status:
        stmt = stmt.where(Live.status.in_(status.split(",")))
    if pro_id:
        stmt = stmt.where(Live.pro_id == pro_id)
    # En direct d'abord, puis les prochains programmés.
    rows = db.scalars(stmt.order_by((Live.status == "live").desc(), Live.scheduled_at)
                      .limit(page.limit).offset(page.offset)).all()
    return [live_out(lv, has_access(db, lv, user)) for lv in rows]


@router.get("/tickets/mine", response_model=list[LiveOut])
def my_tickets(db: Session = Depends(get_db), user: User = Depends(current_user)):
    ids = db.scalars(select(LiveTicket.live_id).where(LiveTicket.user_id == user.id)).all()
    rows = db.scalars(select(Live).where(Live.id.in_(ids)).order_by(Live.scheduled_at.desc())).all()
    return [live_out(lv, True) for lv in rows]


@router.get("/{lid}", response_model=LiveOut)
def get_live(lid: str, db: Session = Depends(get_db), user: User | None = Depends(optional_user)):
    lv = _live(db, lid)
    return live_out(lv, has_access(db, lv, user))


@router.post("", response_model=LiveOut, status_code=201)
def create_live(payload: LiveIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    if payload.mode == "paid" and payload.price_xaf <= 0:
        raise HTTPException(422, "Un live payant doit avoir un prix de billet")
    if payload.mode == "paid" and user.pro.plan == "free":
        raise HTTPException(402, "Les lives payants nécessitent le pack Premium ou Business")
    lv = Live(pro_id=user.id, **payload.model_dump(), status="scheduled")
    lv.scheduled_at = payload.scheduled_at or utcnow()
    db.add(lv)
    db.flush()
    bells = list(db.scalars(select(Follow.follower_id).where(Follow.pro_id == user.id, Follow.notify.is_(True))))
    notify_many(db, bells, "live", f"Live programmé par {user.name}", payload.title, {"live_id": lv.id})
    db.commit()
    db.refresh(lv)
    return live_out(lv, True)


@router.patch("/{lid}", response_model=LiveOut)
def update_live(lid: str, payload: LiveUpdate, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    lv = _own(db, lid, user)
    if lv.status != "scheduled":
        raise HTTPException(409, "Seul un live programmé peut être modifié")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(lv, k, v)
    db.commit()
    return live_out(lv, True)


@router.post("/{lid}/start", response_model=LiveOut)
def start_live(lid: str, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    lv = _own(db, lid, user)
    if lv.status != "scheduled":
        raise HTTPException(409, "Ce live n'est pas en attente de démarrage")
    lv.status = "live"
    lv.started_at = utcnow()
    audience = set(db.scalars(select(Follow.follower_id).where(Follow.pro_id == user.id, Follow.notify.is_(True))))
    audience |= set(db.scalars(select(LiveTicket.user_id).where(LiveTicket.live_id == lid)))
    notify_many(db, list(audience), "live", f"{user.name} est en direct", lv.title, {"live_id": lv.id})
    db.commit()
    return live_out(lv, True)


@router.post("/{lid}/end")
def end_live(lid: str, payload: LiveEndIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    """Fin du live + bilan + politique de replay (UC-PR-14)."""
    lv = _own(db, lid, user)
    if lv.status != "live":
        raise HTTPException(409, "Ce live n'est pas en cours")
    lv.status = "ended"
    lv.ended_at = utcnow()
    lv.viewers = 0
    lv.replay_policy = payload.replay_policy
    lv.replay_price_xaf = payload.replay_price_xaf
    tickets = db.scalars(select(LiveTicket).where(LiveTicket.live_id == lid, LiveTicket.kind == "live")).all()
    db.commit()
    duration = int((lv.ended_at - lv.started_at).total_seconds()) if lv.started_at else 0
    return {
        "live": live_out(lv, True),
        "summary": {
            "duration_seconds": duration,
            "peak_viewers": lv.peak_viewers,
            "tickets_sold": len(tickets),
            "tickets_xaf": sum(t.price_xaf for t in tickets),
            "tips_xaf": lv.tips_xaf,
        },
    }


@router.post("/{lid}/token")
def join_token(lid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Jeton LiveKit : le pro publie, les spectateurs s'abonnent (accès vérifié)."""
    lv = _live(db, lid)
    is_host = lv.pro_id == user.id
    if lv.status != "live" and not is_host:
        raise HTTPException(409, "Le live n'est pas en cours")
    if not has_access(db, lv, user):
        raise HTTPException(402, "Billet requis pour ce live" if lv.mode == "paid"
                            else "Live réservé aux abonnés")
    if not is_host:
        lv.viewers += 1
        lv.peak_viewers = max(lv.peak_viewers, lv.viewers)
        db.commit()
    return livekit.access_token(f"live-{lv.id}", user.id, user.name, can_publish=is_host)


@router.post("/{lid}/leave")
def leave(lid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    lv = _live(db, lid)
    if lv.pro_id != user.id and lv.viewers > 0:
        lv.viewers -= 1
        db.commit()
    return {"viewers": lv.viewers}


def _sell(db: Session, lv: Live, user: User, kind: str, price: int) -> LiveTicket:
    if _has_ticket(db, lv.id, user.id, kind):
        raise HTTPException(409, "Vous avez déjà accès")
    ledger.require_2fa_if_needed(db, user, price)
    label = ("Billet" if kind == "live" else "Replay") + f" « {lv.title} »"
    ledger.debit(db, user.id, price, "ticket", label, related_id=lv.id)
    fee = commission(db, "live", price)
    ledger.credit(db, lv.pro_id, price, "ticket_payout", f"{label} — {user.name}", related_id=lv.id)
    if fee:
        ledger.debit(db, lv.pro_id, fee, "commission", f"Commission ProLink — {label}", related_id=lv.id)
    t = LiveTicket(live_id=lv.id, user_id=user.id, kind=kind, price_xaf=price)
    db.add(t)
    return t


@router.post("/{lid}/ticket", response_model=LiveOut, status_code=201)
def buy_ticket(lid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    lv = _live(db, lid)
    if lv.mode != "paid":
        raise HTTPException(409, "Ce live est gratuit")
    if lv.status not in ("scheduled", "live"):
        raise HTTPException(409, "Billetterie fermée")
    _sell(db, lv, user, "live", lv.price_xaf)
    db.commit()
    return live_out(lv, True)


@router.post("/{lid}/replay", response_model=LiveOut, status_code=201)
def buy_replay(lid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    lv = _live(db, lid)
    if lv.status != "ended" or lv.replay_policy != "paid":
        raise HTTPException(409, "Replay non disponible à l'achat")
    _sell(db, lv, user, "replay", lv.replay_price_xaf)
    db.commit()
    return live_out(lv, True)


@router.post("/{lid}/tip")
def tip(lid: str, payload: TipIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    lv = _live(db, lid)
    if lv.status != "live":
        raise HTTPException(409, "Les pourboires sont possibles uniquement pendant le direct")
    if lv.pro_id == user.id:
        raise HTTPException(400, "Impossible de vous envoyer un pourboire")
    amount = payload.amount_xaf
    ledger.require_2fa_if_needed(db, user, amount)
    ledger.debit(db, user.id, amount, "tip", f"Pourboire — {lv.title}", related_id=lv.id)
    fee = commission(db, "tip", amount)
    ledger.credit(db, lv.pro_id, amount, "tip_payout", f"Pourboire de {user.name}", related_id=lv.id)
    if fee:
        ledger.debit(db, lv.pro_id, fee, "commission", "Commission ProLink — pourboire", related_id=lv.id)
    lv.tips_xaf += amount
    notify(db, lv.pro_id, "payment", "Pourboire reçu", f"{user.name} : {amount} XAF", {"live_id": lv.id})
    db.commit()
    return {"live": lv.id, "amount_xaf": amount, "commission_xaf": fee, "net_to_pro_xaf": amount - fee}
