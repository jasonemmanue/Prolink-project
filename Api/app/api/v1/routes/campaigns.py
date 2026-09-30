from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.deps import current_user, require_pro
from app.db import get_db
from app.models import Campaign, Post, Service, User
from app.schemas import CampaignIn, CampaignOut, campaign_out
from app.services import cache, ledger
from app.services.platform import get_setting

router = APIRouter(prefix="/campaigns", tags=["sponsoring"])


def _own(db: Session, cid: str, user: User) -> Campaign:
    c = db.get(Campaign, cid)
    if not c or c.owner_id != user.id:
        raise HTTPException(404, "Campagne introuvable")
    return c


@router.post("/estimate")
def estimate(payload: CampaignIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    cfg = get_setting(db, "sponsorship")
    total = payload.daily_budget_xaf * payload.days
    reach = round(total / 1000 * cfg["reach_per_1000_xaf"])
    return {"total_xaf": total, "reach_min": reach, "reach_max": round(reach * 1.6)}


@router.post("", response_model=CampaignOut, status_code=201)
def create(payload: CampaignIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    """Sponsorisation en 3 taps : budget débité, campagne soumise à validation admin."""
    if payload.target_type == "post":
        p = db.get(Post, payload.target_id or "")
        if not p or p.author_id != user.id:
            raise HTTPException(404, "Publication introuvable")
    elif payload.target_type == "service":
        s = db.get(Service, payload.target_id or "")
        if not s or s.pro_id != user.id:
            raise HTTPException(404, "Prestation introuvable")
    else:
        payload.target_id = user.id
    c = Campaign(owner_id=user.id, **payload.model_dump())
    db.add(c)
    db.flush()
    ledger.debit(db, user.id, c.total_xaf, "sponsorship",
                 f"Sponsorisation {payload.target_type} — {payload.days} j", related_id=c.id)
    db.commit()
    cache.invalidate("feed")
    db.refresh(c)
    return campaign_out(c)


@router.get("", response_model=list[CampaignOut])
def mine(db: Session = Depends(get_db), user: User = Depends(current_user)):
    rows = db.scalars(select(Campaign).where(Campaign.owner_id == user.id)
                      .order_by(Campaign.created_at.desc())).all()
    return [campaign_out(c) for c in rows]


@router.post("/{cid}/pause", response_model=CampaignOut)
def pause(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    c = _own(db, cid, user)
    if c.status != "active":
        raise HTTPException(409, "Seule une campagne active peut être mise en pause")
    c.status = "paused"
    db.commit()
    cache.invalidate("feed")
    return campaign_out(c)


@router.post("/{cid}/resume", response_model=CampaignOut)
def resume(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    c = _own(db, cid, user)
    if c.status != "paused":
        raise HTTPException(409, "Campagne non en pause")
    c.status = "active"
    db.commit()
    cache.invalidate("feed")
    return campaign_out(c)


@router.post("/{cid}/stop", response_model=CampaignOut)
def stop(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Arrêt : le budget non dépensé est restitué."""
    c = _own(db, cid, user)
    if c.status in ("ended", "rejected"):
        raise HTTPException(409, "Campagne déjà clôturée")
    remaining = c.total_xaf - c.spent_xaf
    if remaining > 0:
        ledger.credit(db, user.id, remaining, "refund", "Budget sponsorisation non dépensé",
                      related_id=c.id)
    c.status = "ended"
    db.commit()
    cache.invalidate("feed")
    return campaign_out(c)
