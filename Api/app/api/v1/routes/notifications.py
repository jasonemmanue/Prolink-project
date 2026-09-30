from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import func, select, update
from sqlalchemy.orm import Session

from app.core.deps import Page, current_user
from app.db import get_db
from app.models import DeviceToken, Notification, User
from app.schemas import DeviceTokenIn, NotificationOut, notification_out

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.get("", response_model=list[NotificationOut])
def list_notifications(kind: str | None = None, unread_only: bool = False, page: Page = Depends(),
                       db: Session = Depends(get_db), user: User = Depends(current_user)):
    stmt = select(Notification).where(Notification.user_id == user.id)
    if kind:
        stmt = stmt.where(Notification.kind.in_(kind.split(",")))
    if unread_only:
        stmt = stmt.where(Notification.read.is_(False))
    rows = db.scalars(stmt.order_by(Notification.created_at.desc())
                      .limit(page.limit).offset(page.offset)).all()
    return [notification_out(n) for n in rows]


@router.get("/unread-count")
def unread_count(db: Session = Depends(get_db), user: User = Depends(current_user)):
    n = db.scalar(select(func.count(Notification.id)).where(Notification.user_id == user.id,
                                                            Notification.read.is_(False)))
    return {"unread": n or 0}


@router.post("/{nid}/read", response_model=NotificationOut)
def mark_read(nid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    n = db.get(Notification, nid)
    if not n or n.user_id != user.id:
        raise HTTPException(404, "Notification introuvable")
    n.read = True
    db.commit()
    return notification_out(n)


@router.post("/read-all")
def read_all(db: Session = Depends(get_db), user: User = Depends(current_user)):
    res = db.execute(update(Notification).where(Notification.user_id == user.id,
                                                Notification.read.is_(False)).values(read=True))
    db.commit()
    return {"updated": res.rowcount}


@router.post("/devices", status_code=201)
def register_device(payload: DeviceTokenIn, db: Session = Depends(get_db),
                    user: User = Depends(current_user)):
    """Jeton Firebase Cloud Messaging de l'appareil."""
    row = db.scalars(select(DeviceToken).where(DeviceToken.token == payload.token)).first()
    if row:
        row.user_id, row.platform = user.id, payload.platform
    else:
        db.add(DeviceToken(user_id=user.id, token=payload.token, platform=payload.platform))
    db.commit()
    return {"stored": True, "platform": payload.platform}


@router.delete("/devices/{token}", status_code=204)
def unregister_device(token: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    row = db.scalars(select(DeviceToken).where(DeviceToken.token == token,
                                               DeviceToken.user_id == user.id)).first()
    if row:
        db.delete(row)
        db.commit()
