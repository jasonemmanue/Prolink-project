"""Paramètres plateforme (commissions, packs) + audit + modération."""
import re

from fastapi import HTTPException
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db import utcnow
from app.models import AuditLog, BannedKeyword, PlatformSetting

DEFAULTS: dict[str, dict] = {
    "commissions": {
        "service_pct": settings.commission_service_pct,
        "live_pct": settings.commission_live_pct,
        "tip_pct": settings.commission_tip_pct,
    },
    "plans": {
        "free": {"price_xaf": 0, "label": "Gratuit", "max_services": 5},
        "premium": {"price_xaf": 9900, "label": "Premium", "max_services": None},
        "business": {"price_xaf": 29900, "label": "Business", "max_services": None},
    },
    "sponsorship": {"min_daily_xaf": 1000, "max_daily_xaf": 50000, "reach_per_1000_xaf": 420},
    "legal": {"cgu_version": "1.0", "privacy_version": "1.0"},
}


def get_setting(db: Session, key: str) -> dict:
    row = db.get(PlatformSetting, key)
    if row:
        return {**DEFAULTS.get(key, {}), **row.value}
    return dict(DEFAULTS.get(key, {}))


def set_setting(db: Session, key: str, value: dict) -> dict:
    row = db.get(PlatformSetting, key)
    merged = {**get_setting(db, key), **value}
    if row:
        row.value = merged
        row.updated_at = utcnow()
    else:
        db.add(PlatformSetting(key=key, value=merged, updated_at=utcnow()))
    return merged


def commission(db: Session, kind: str, amount: int) -> int:
    pct = get_setting(db, "commissions")[f"{kind}_pct"]
    return round(amount * float(pct) / 100)


def audit(db: Session, actor_id: str, action: str, target_type: str | None = None,
          target_id: str | None = None, payload: dict | None = None, ip: str | None = None) -> None:
    db.add(AuditLog(actor_id=actor_id, action=action, target_type=target_type,
                    target_id=target_id, payload=payload or {}, ip=ip))


def moderate_text(db: Session, text: str) -> str:
    """Masque les mots-clés interdits configurés par l'admin."""
    words = db.scalars(select(BannedKeyword.word)).all()
    for w in words:
        text = re.sub(re.escape(w), "*" * len(w), text, flags=re.IGNORECASE)
    return text


def ensure(cond: bool, message: str, code: int = 400) -> None:
    if not cond:
        raise HTTPException(code, message)
