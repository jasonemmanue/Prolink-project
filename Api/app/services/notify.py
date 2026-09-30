"""Notifications : ligne en base + WebSocket temps réel + push FCM."""
import logging

from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.models import DeviceToken, Notification
from app.services.realtime import hub

log = logging.getLogger("prolink.notify")


def notify(db: Session, user_id: str, kind: str, title: str, body: str = "",
           data: dict | None = None) -> Notification:
    n = Notification(user_id=user_id, kind=kind, title=title, body=body, data=data or {})
    db.add(n)
    db.flush()
    hub.publish_sync([user_id], {
        "type": "notification",
        "notification": {"id": n.id, "kind": kind, "title": title, "body": body, "data": n.data},
    })
    _push_fcm(db, user_id, title, body, data or {})
    return n


def notify_many(db: Session, user_ids: list[str], kind: str, title: str, body: str = "",
                data: dict | None = None) -> int:
    for uid in user_ids:
        notify(db, uid, kind, title, body, data)
    return len(user_ids)


def _push_fcm(db: Session, user_id: str, title: str, body: str, data: dict) -> None:
    tokens = db.scalars(select(DeviceToken.token).where(DeviceToken.user_id == user_id)).all()
    if not tokens:
        return
    if not settings.firebase_project_id:
        log.info("FCM non configuré — push simulé pour %s (%d appareil(s)) : %s",
                 user_id, len(tokens), title)
        return
    # Production : firebase_admin.messaging.send_each_for_multicast(...)
    log.info("FCM push → %s : %s", user_id, title)
