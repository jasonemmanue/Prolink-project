from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.deps import Page, current_user, require_pro
from app.db import get_db, utcnow
from app.models import Dispute, Order, QuoteRequest, Review, Service, User
from app.schemas import (
    DeliverIn, DisputeIn, DisputeMessageIn, DisputeOut, OrderIn, OrderOut, ReviewIn,
    ReviewOut, ReviewReplyIn, order_out, review_out,
)
from app.services import orders as svc
from app.services.notify import notify
from app.services.platform import moderate_text

router = APIRouter(tags=["orders"])


def _order(db: Session, oid: str, user: User) -> Order:
    o = db.get(Order, oid) or db.scalars(select(Order).where(Order.code == oid)).first()
    if not o or (user.id not in (o.client_id, o.pro_id) and user.role != "admin"):
        raise HTTPException(404, "Commande introuvable")
    return o


def _state(o: Order, *allowed: str) -> None:
    if o.status not in allowed:
        raise HTTPException(409, f"Action impossible : la commande est « {o.status} »")


def _out(db: Session, o: Order) -> OrderOut:
    reviewed = db.scalars(select(Review.id).where(Review.order_id == o.id)).first() is not None
    return order_out(o, reviewed)


@router.post("/orders", response_model=OrderOut, status_code=201)
def create_order(payload: OrderIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Commande d'une prestation : les fonds sont immédiatement placés en séquestre."""
    s = db.get(Service, payload.service_id)
    if not s or s.status != "active":
        raise HTTPException(404, "Prestation indisponible")
    if s.pricing_type == "quote":
        raise HTTPException(409, "Prestation sur devis : utilisez POST /quotes")
    o = svc.create_order(
        db, user, s.pro_id, s.title, s.price_for(payload.variant), service_id=s.id,
        variant=payload.variant, brief=payload.brief, slot=payload.slot,
        method=payload.payment_method, phone=payload.phone,
    )
    db.commit()
    db.refresh(o)
    return _out(db, o)


@router.post("/quotes/{qid}/accept", response_model=OrderOut, status_code=201, tags=["quotes"])
def accept_quote(qid: str, payment_method: str = Query("wallet", pattern="^(wallet|mtn|orange|card)$"),
                 phone: str | None = None, db: Session = Depends(get_db),
                 user: User = Depends(current_user)):
    q = db.get(QuoteRequest, qid)
    if not q or q.client_id != user.id:
        raise HTTPException(404, "Devis introuvable")
    if q.status != "quoted":
        raise HTTPException(409, "Ce devis n'a pas encore été chiffré ou est clôturé")
    title = db.get(Service, q.service_id).title if q.service_id and db.get(Service, q.service_id) else "Prestation sur devis"
    o = svc.create_order(db, user, q.pro_id, title, q.total_xaf, service_id=q.service_id,
                         variant=None, brief=q.description, slot=None,
                         method=payment_method, phone=phone)
    q.status = "accepted"
    q.order_id = o.id
    db.commit()
    db.refresh(o)
    return _out(db, o)


@router.get("/orders", response_model=list[OrderOut])
def list_orders(role: str = Query("any", pattern="^(any|client|pro)$"), status: str | None = None,
                page: Page = Depends(), db: Session = Depends(get_db),
                user: User = Depends(current_user)):
    cond = {
        "client": Order.client_id == user.id,
        "pro": Order.pro_id == user.id,
    }.get(role, or_(Order.client_id == user.id, Order.pro_id == user.id))
    stmt = select(Order).where(cond)
    if status:
        stmt = stmt.where(Order.status.in_(status.split(",")))
    rows = db.scalars(stmt.order_by(Order.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [_out(db, o) for o in rows]


@router.get("/orders/{oid}", response_model=OrderOut)
def get_order(oid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    return _out(db, _order(db, oid, user))


@router.post("/orders/{oid}/confirm", response_model=OrderOut)
def confirm(oid: str, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    o = _order(db, oid, user)
    if o.pro_id != user.id:
        raise HTTPException(403, "Réservé au professionnel")
    _state(o, "pending")
    o.status = "in_progress"
    o.confirmed_at = utcnow()
    notify(db, o.client_id, "order", "Commande confirmée", f"{user.name} a pris en charge {o.code}.",
           {"order_id": o.id})
    db.commit()
    return _out(db, o)


@router.post("/orders/{oid}/decline", response_model=OrderOut)
def decline(oid: str, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    o = _order(db, oid, user)
    if o.pro_id != user.id:
        raise HTTPException(403, "Réservé au professionnel")
    _state(o, "pending")
    svc.refund(db, o, "commande refusée par le professionnel")
    db.commit()
    return _out(db, o)


@router.post("/orders/{oid}/cancel", response_model=OrderOut)
def cancel(oid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    o = _order(db, oid, user)
    if o.client_id != user.id:
        raise HTTPException(403, "Réservé au client")
    _state(o, "pending", "awaiting_payment")
    if o.status == "awaiting_payment":
        o.status = "cancelled"
        o.cancelled_at = utcnow()
    else:
        svc.refund(db, o, "annulée avant prise en charge")
        notify(db, o.pro_id, "order", "Commande annulée", f"{o.code} a été annulée par le client.",
               {"order_id": o.id})
    db.commit()
    return _out(db, o)


@router.post("/orders/{oid}/deliver", response_model=OrderOut)
def deliver(oid: str, payload: DeliverIn, db: Session = Depends(get_db),
            user: User = Depends(require_pro)):
    o = _order(db, oid, user)
    if o.pro_id != user.id:
        raise HTTPException(403, "Réservé au professionnel")
    _state(o, "in_progress")
    o.status = "delivered"
    o.delivered_at = utcnow()
    o.delivery_message = payload.message
    o.deliverables = payload.deliverables
    notify(db, o.client_id, "order", f"Commande {o.code} livrée",
           "Validez la prestation pour libérer le séquestre (automatique sous 72 h).",
           {"order_id": o.id})
    db.commit()
    return _out(db, o)


@router.post("/orders/{oid}/validate", response_model=OrderOut)
def validate(oid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Le client valide : les fonds sont libérés au pro, commission déduite."""
    o = _order(db, oid, user)
    if o.client_id != user.id:
        raise HTTPException(403, "Réservé au client")
    _state(o, "delivered")
    svc.complete(db, o)
    db.commit()
    return _out(db, o)


# -------------------------------------------------------------------- litiges

@router.post("/orders/{oid}/dispute", response_model=DisputeOut, status_code=201)
def open_dispute(oid: str, payload: DisputeIn, db: Session = Depends(get_db),
                 user: User = Depends(current_user)):
    o = _order(db, oid, user)
    _state(o, "pending", "in_progress", "delivered")
    d = Dispute(order_id=o.id, opened_by=user.id, reason=payload.reason, remedy=payload.remedy,
                description=payload.description, evidence=payload.evidence,
                events=[{"at": utcnow().isoformat(), "by": user.id,
                         "text": f"Litige ouvert : {payload.reason}"}])
    db.add(d)
    o.status = "disputed"
    other = o.pro_id if user.id == o.client_id else o.client_id
    notify(db, other, "order", f"Litige ouvert sur {o.code}",
           "Le séquestre est gelé. Un médiateur ProLink va examiner le dossier.", {"order_id": o.id})
    db.commit()
    db.refresh(d)
    return d


@router.get("/orders/{oid}/dispute", response_model=DisputeOut)
def get_dispute(oid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    o = _order(db, oid, user)
    d = db.scalars(select(Dispute).where(Dispute.order_id == o.id)).first()
    if not d:
        raise HTTPException(404, "Aucun litige sur cette commande")
    return d


@router.post("/orders/{oid}/dispute/messages", response_model=DisputeOut)
def dispute_message(oid: str, payload: DisputeMessageIn, db: Session = Depends(get_db),
                    user: User = Depends(current_user)):
    o = _order(db, oid, user)
    d = db.scalars(select(Dispute).where(Dispute.order_id == o.id)).first()
    if not d or d.status != "open":
        raise HTTPException(409, "Aucun litige ouvert")
    d.events = [*d.events, {"at": utcnow().isoformat(), "by": user.id, "text": payload.text}]
    db.commit()
    return d


# ----------------------------------------------------------------------- avis

@router.post("/orders/{oid}/review", response_model=ReviewOut, status_code=201, tags=["reviews"])
def review(oid: str, payload: ReviewIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    o = _order(db, oid, user)
    if o.client_id != user.id:
        raise HTTPException(403, "Seul le client peut noter")
    _state(o, "completed")
    if db.scalars(select(Review).where(Review.order_id == o.id)).first():
        raise HTTPException(409, "Avis déjà publié")
    r = Review(order_id=o.id, author_id=user.id, pro_id=o.pro_id, stars=payload.stars,
               text=moderate_text(db, payload.text), tags=payload.tags)
    db.add(r)
    db.flush()
    svc.refresh_rating(db, o.pro_id)
    notify(db, o.pro_id, "review", f"Nouvel avis {payload.stars}★", payload.text[:120], {"review_id": r.id})
    db.commit()
    db.refresh(r)
    return review_out(r)


@router.post("/reviews/{rid}/reply", response_model=ReviewOut, tags=["reviews"])
def reply_review(rid: str, payload: ReviewReplyIn, db: Session = Depends(get_db),
                 user: User = Depends(require_pro)):
    r = db.get(Review, rid)
    if not r or r.pro_id != user.id:
        raise HTTPException(404, "Avis introuvable")
    r.reply = moderate_text(db, payload.reply)
    db.commit()
    return review_out(r)
