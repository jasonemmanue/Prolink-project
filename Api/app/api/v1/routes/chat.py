from fastapi import APIRouter, Depends, HTTPException, Query, WebSocket, WebSocketDisconnect
from starlette.concurrency import run_in_threadpool
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.deps import Page, _user_from_token, current_user, require_pro
from app.db import SessionLocal, get_db, utcnow
from app.models import Conversation, ConversationMember, Message, User
from app.schemas import (
    ConversationOut, DirectIn, GroupIn, MemberPrefsIn, MessageIn, MessageOut, message_out,
    user_public,
)
from app.services import ledger
from app.services.notify import notify
from app.services.platform import commission, moderate_text
from app.services.realtime import hub
from app.services.translation import detect

router = APIRouter(prefix="/chat", tags=["chat"])


def _membership(db: Session, cid: str, uid: str) -> ConversationMember | None:
    return db.scalars(select(ConversationMember).where(ConversationMember.conversation_id == cid,
                                                       ConversationMember.user_id == uid)).first()


def _conv_for(db: Session, cid: str, user: User, need_member: bool = True) -> Conversation:
    c = db.get(Conversation, cid)
    if not c:
        raise HTTPException(404, "Conversation introuvable")
    m = _membership(db, cid, user.id)
    if need_member and (not m or m.status != "member"):
        raise HTTPException(403, "Vous n'êtes pas membre de cette conversation")
    return c


def _member_ids(db: Session, cid: str) -> list[str]:
    return list(db.scalars(select(ConversationMember.user_id).where(
        ConversationMember.conversation_id == cid, ConversationMember.status == "member")))


def _conv_out(db: Session, c: Conversation, me: User) -> ConversationOut:
    m = _membership(db, c.id, me.id)
    last = db.scalars(select(Message).where(Message.conversation_id == c.id)
                      .order_by(Message.created_at.desc())).first()
    unread = 0
    if m and m.status == "member":
        stmt = select(func.count(Message.id)).where(Message.conversation_id == c.id,
                                                    Message.author_id != me.id)
        if m.last_read_at:
            stmt = stmt.where(Message.created_at > m.last_read_at)
        unread = db.scalar(stmt) or 0
    members = _member_ids(db, c.id)
    peer = None
    if c.kind == "direct":
        other = next((uid for uid in members if uid != me.id), None)
        peer = db.get(User, other) if other else None
    host = db.get(User, c.host_id) if c.host_id else None
    return ConversationOut(
        id=c.id, kind=c.kind,
        title=c.title or (peer.name if peer else "Conversation"),
        avatar_url=peer.avatar_url if peer else (host.avatar_url if host else None),
        peer=user_public(peer) if peer else None, host=user_public(host) if host else None,
        description=c.description, access=c.access, price_xaf=c.price_xaf,
        members_count=len(members), my_status=m.status if m else None,
        last_message=message_out(last) if last else None, unread=unread,
        archived=bool(m and m.archived), pinned=bool(m and m.pinned),
        online=bool(peer and hub.is_online(peer.id)),
    )


@router.get("/conversations", response_model=list[ConversationOut])
def conversations(archived: bool = False, db: Session = Depends(get_db),
                  user: User = Depends(current_user)):
    rows = db.scalars(
        select(Conversation).join(ConversationMember)
        .where(ConversationMember.user_id == user.id, ConversationMember.status == "member",
               ConversationMember.archived.is_(archived))
        .order_by(ConversationMember.pinned.desc(), Conversation.last_message_at.desc().nulls_last())
    ).all()
    return [_conv_out(db, c, user) for c in rows]


@router.post("/conversations", response_model=ConversationOut, status_code=201)
def open_direct(payload: DirectIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Ouvre (ou retrouve) la conversation privée avec un utilisateur."""
    other = db.get(User, payload.user_id)
    if not other or other.id == user.id:
        raise HTTPException(404, "Destinataire introuvable")
    mine = select(ConversationMember.conversation_id).where(ConversationMember.user_id == user.id)
    existing = db.scalars(
        select(Conversation).join(ConversationMember)
        .where(Conversation.kind == "direct", Conversation.id.in_(mine),
               ConversationMember.user_id == other.id)
    ).first()
    if existing:
        return _conv_out(db, existing, user)
    c = Conversation(kind="direct")
    db.add(c)
    db.flush()
    db.add_all([ConversationMember(conversation_id=c.id, user_id=user.id),
                ConversationMember(conversation_id=c.id, user_id=other.id)])
    db.commit()
    return _conv_out(db, c, user)


@router.get("/conversations/{cid}", response_model=ConversationOut)
def get_conversation(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    c = _conv_for(db, cid, user, need_member=False)
    if c.kind == "direct" and not _membership(db, cid, user.id):
        raise HTTPException(404, "Conversation introuvable")
    return _conv_out(db, c, user)


@router.patch("/conversations/{cid}", response_model=ConversationOut)
def conversation_prefs(cid: str, payload: MemberPrefsIn, db: Session = Depends(get_db),
                       user: User = Depends(current_user)):
    c = _conv_for(db, cid, user)
    m = _membership(db, cid, user.id)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(m, k, v)
    db.commit()
    return _conv_out(db, c, user)


@router.get("/conversations/{cid}/messages", response_model=list[MessageOut])
def messages(cid: str, before: str | None = Query(None, description="id de message (pagination)"),
             page: Page = Depends(), db: Session = Depends(get_db), user: User = Depends(current_user)):
    _conv_for(db, cid, user)
    stmt = select(Message).where(Message.conversation_id == cid)
    if before and (ref := db.get(Message, before)):
        stmt = stmt.where(Message.created_at < ref.created_at)
    rows = db.scalars(stmt.order_by(Message.created_at.desc()).limit(page.limit)).all()
    return [message_out(m) for m in reversed(rows)]


def _post_message(db: Session, cid: str, user: User, payload: MessageIn) -> Message:
    c = _conv_for(db, cid, user)
    if c.kind == "group" and c.only_host_posts and c.host_id != user.id:
        raise HTTPException(403, "Seul l'animateur peut publier dans ce groupe")
    if not payload.text.strip() and not payload.attachments:
        raise HTTPException(422, "Message vide")
    text = moderate_text(db, payload.text)
    msg = Message(conversation_id=cid, author_id=user.id, text=text,
                  lang=detect(text) if text.strip() else None, attachments=payload.attachments)
    db.add(msg)
    c.last_message_at = utcnow()
    _membership(db, cid, user.id).last_read_at = utcnow()
    db.flush()
    others = [uid for uid in _member_ids(db, cid) if uid != user.id]
    if c.kind == "direct":
        for uid in others:
            if not hub.is_online(uid):
                notify(db, uid, "message", f"Nouveau message de {user.name}", text[:120],
                       {"conversation_id": cid})
    db.commit()
    db.refresh(msg)
    return msg


@router.post("/conversations/{cid}/messages", response_model=MessageOut, status_code=201)
def send_message(cid: str, payload: MessageIn, db: Session = Depends(get_db),
                 user: User = Depends(current_user)):
    msg = _post_message(db, cid, user, payload)
    hub.publish_sync(_member_ids(db, cid), {"type": "message",
                                            "message": message_out(msg).model_dump(mode="json")})
    return message_out(msg)


@router.post("/conversations/{cid}/read")
def mark_read(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    _conv_for(db, cid, user)
    _membership(db, cid, user.id).last_read_at = utcnow()
    db.commit()
    hub.publish_sync(_member_ids(db, cid), {"type": "read", "conversation_id": cid, "user_id": user.id})
    return {"read": True}


# --------------------------------------------------------------------- groupes

@router.get("/groups", response_model=list[ConversationOut])
def list_groups(q: str | None = None, db: Session = Depends(get_db), user: User = Depends(current_user)):
    stmt = select(Conversation).where(Conversation.kind == "group")
    if q:
        stmt = stmt.where(func.lower(Conversation.title).like(f"%{q.lower()}%"))
    return [_conv_out(db, c, user) for c in db.scalars(stmt.order_by(Conversation.created_at.desc()))]


@router.post("/groups", response_model=ConversationOut, status_code=201)
def create_group(payload: GroupIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    if payload.access == "paid" and payload.price_xaf <= 0:
        raise HTTPException(422, "Un groupe payant doit avoir un prix")
    c = Conversation(kind="group", host_id=user.id, **payload.model_dump())
    db.add(c)
    db.flush()
    db.add(ConversationMember(conversation_id=c.id, user_id=user.id))
    db.commit()
    return _conv_out(db, c, user)


@router.post("/groups/{cid}/join", response_model=ConversationOut)
def join_group(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    c = _conv_for(db, cid, user, need_member=False)
    if c.kind != "group":
        raise HTTPException(404, "Groupe introuvable")
    m = _membership(db, cid, user.id)
    if m and m.status == "member":
        return _conv_out(db, c, user)
    if c.access == "paid":
        ledger.debit(db, user.id, c.price_xaf, "subscription", f"Abonnement groupe « {c.title} »",
                     related_id=c.id)
        ledger.credit(db, c.host_id, c.price_xaf, "group_payout", f"Abonnement groupe — {user.name}",
                      related_id=c.id)
        fee = commission(db, "service", c.price_xaf)
        if fee:
            ledger.debit(db, c.host_id, fee, "commission", f"Commission ProLink — groupe « {c.title} »",
                         related_id=c.id)
    status = "requested" if c.access == "private" else "member"
    if m:
        m.status = status
    else:
        db.add(ConversationMember(conversation_id=cid, user_id=user.id, status=status))
    if status == "requested":
        notify(db, c.host_id, "message", "Demande d'adhésion", f"{user.name} souhaite rejoindre « {c.title} ».",
               {"conversation_id": cid, "user_id": user.id})
    db.commit()
    return _conv_out(db, c, user)


@router.post("/groups/{cid}/members/{uid}/approve", response_model=ConversationOut)
def approve_member(cid: str, uid: str, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    c = _conv_for(db, cid, user)
    if c.host_id != user.id:
        raise HTTPException(403, "Réservé à l'animateur")
    m = _membership(db, cid, uid)
    if not m:
        raise HTTPException(404, "Aucune demande")
    m.status = "member"
    notify(db, uid, "message", "Demande acceptée", f"Bienvenue dans « {c.title} » !", {"conversation_id": cid})
    db.commit()
    return _conv_out(db, c, user)


@router.post("/groups/{cid}/leave", status_code=204)
def leave_group(cid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    c = _conv_for(db, cid, user, need_member=False)
    m = _membership(db, cid, user.id)
    if c.host_id == user.id:
        raise HTTPException(409, "L'animateur ne peut pas quitter son groupe")
    if m:
        db.delete(m)
        db.commit()


# ------------------------------------------------------------------- WebSocket

@router.websocket("/ws")
async def ws(websocket: WebSocket, token: str = Query(...)):
    """Canal temps réel unique par utilisateur.

    Reçoit : messages, accusés de lecture, notifications.
    Envoie : {"type": "message", "conversation_id": ..., "text": ...}
             {"type": "typing", "conversation_id": ...}
    """
    db = SessionLocal()
    try:
        user = await run_in_threadpool(_user_from_token, db, token)
    finally:
        db.close()
    if not user:
        await websocket.close(code=4401)
        return
    await websocket.accept()
    hub.connect(user.id, websocket)
    await websocket.send_json({"type": "ready", "user_id": user.id})
    try:
        while True:
            data = await websocket.receive_json()
            kind = data.get("type")
            cid = data.get("conversation_id")
            if kind == "message" and cid:
                try:
                    out = await run_in_threadpool(_ws_send, user.id, cid, data)
                except HTTPException as e:
                    await websocket.send_json({"type": "error", "detail": e.detail})
                    continue
                await hub.publish(out["members"], {"type": "message", "message": out["message"]})
            elif kind == "typing" and cid:
                members = await run_in_threadpool(_ws_members, user.id, cid)
                await hub.publish([m for m in members if m != user.id],
                                  {"type": "typing", "conversation_id": cid, "user_id": user.id})
            elif kind == "ping":
                await websocket.send_json({"type": "pong"})
    except WebSocketDisconnect:
        pass
    finally:
        hub.disconnect(user.id, websocket)


def _ws_send(user_id: str, cid: str, data: dict) -> dict:
    db = SessionLocal()
    try:
        user = db.get(User, user_id)
        msg = _post_message(db, cid, user, MessageIn(text=data.get("text", ""),
                                                     attachments=data.get("attachments", [])))
        return {"members": _member_ids(db, cid), "message": message_out(msg).model_dump(mode="json")}
    finally:
        db.close()


def _ws_members(user_id: str, cid: str) -> list[str]:
    db = SessionLocal()
    try:
        m = _membership(db, cid, user_id)
        return _member_ids(db, cid) if m and m.status == "member" else []
    finally:
        db.close()
