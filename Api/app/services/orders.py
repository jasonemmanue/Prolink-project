"""Cycle de vie des commandes escrow (annexe C.1 du cahier des charges)."""
import secrets
from datetime import timedelta

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db import utcnow
from app.models import Order, ProProfile, Review, Transaction, User
from app.services import ledger, payments
from app.services.notify import notify
from app.services.platform import commission


def new_code(db: Session) -> str:
    while True:
        code = f"PL-{secrets.randbelow(90000) + 10000}"
        if not db.scalars(select(Order.id).where(Order.code == code)).first():
            return code


def create_order(db: Session, client: User, pro_id: str, title: str, amount: int, *,
                 service_id: str | None, variant: str | None, brief: str | None, slot: str | None,
                 method: str, phone: str | None, deadline_days: int = 14) -> Order:
    if pro_id == client.id:
        raise HTTPException(400, "Impossible de commander votre propre prestation")
    if amount <= 0:
        raise HTTPException(400, "Montant invalide")
    ledger.require_2fa_if_needed(db, client, amount)
    order = Order(code=new_code(db), client_id=client.id, pro_id=pro_id, service_id=service_id,
                  title=title, variant=variant, brief=brief, slot=slot, amount_xaf=amount,
                  commission_xaf=commission(db, "service", amount), payment_method=method,
                  status="awaiting_payment",
                  deadline=utcnow() + timedelta(days=deadline_days))
    db.add(order)
    db.flush()

    if method == "wallet":
        _fund(db, order)
        return order

    # Mobile Money / carte : on crédite le portefeuille via CinetPay puis on bloque.
    topup = ledger.record(db, client.id, "topup", amount, f"Paiement commande {order.code}",
                          status="pending", method=method, phone=phone, related_id=order.id,
                          prefix="PAY")
    res = payments.init_payment(topup.reference, amount, f"ProLink {order.code}", phone,
                                "/api/v1/wallet/cinetpay/notify")
    if res["status"] == "completed":
        confirm_topup(db, topup)
    elif res["status"] == "failed":
        raise HTTPException(502, "Le paiement Mobile Money n'a pas pu être initié")
    else:
        topup.meta = {"payment_url": res["payment_url"]}
    return order


def _fund(db: Session, order: Order) -> None:
    ledger.hold_order_funds(db, order.client_id, order.pro_id, order.amount_xaf,
                            order.net_xaf, order.id, f"{order.title} ({order.code})", order.payment_method)
    order.status = "pending"
    notify(db, order.pro_id, "order", "Nouvelle commande",
           f"{order.title} — {order.amount_xaf} XAF (séquestre)", {"order_id": order.id})


def confirm_topup(db: Session, tx: Transaction) -> None:
    """Paiement confirmé (sandbox ou webhook CinetPay)."""
    if tx.status == "completed":
        return
    tx.status = "completed"
    ledger.wallet_of(db, tx.user_id, lock=True).balance_xaf += tx.amount_xaf
    if tx.related_id:
        order = db.get(Order, tx.related_id)
        if order and order.status == "awaiting_payment":
            _fund(db, order)
    else:
        notify(db, tx.user_id, "payment", "Rechargement réussi",
               f"+ {tx.amount_xaf} XAF via {tx.method}", {"tx": tx.reference})


def complete(db: Session, order: Order, by: str = "client") -> None:
    ledger.release_order_funds(db, order.client_id, order.pro_id, order.amount_xaf,
                               order.commission_xaf, order.id, f"{order.title} ({order.code})")
    order.status = "completed"
    order.completed_at = utcnow()
    notify(db, order.pro_id, "payment", "Paiement libéré",
           f"{order.net_xaf} XAF crédités pour {order.code}"
           + (" (validation automatique)" if by == "auto" else ""), {"order_id": order.id})
    notify(db, order.client_id, "review", "Laissez un avis",
           f"Comment s'est passée la prestation « {order.title} » ?", {"order_id": order.id})


def refund(db: Session, order: Order, reason: str) -> None:
    ledger.refund_order_funds(db, order.client_id, order.pro_id, order.amount_xaf, order.net_xaf,
                              order.id, f"{order.title} ({order.code})")
    order.status = "cancelled"
    order.cancelled_at = utcnow()
    notify(db, order.client_id, "payment", "Commande remboursée",
           f"{order.amount_xaf} XAF recrédités — {reason}", {"order_id": order.id})


def release_due_orders(db: Session) -> int:
    """Libération automatique 72 h après livraison sans réponse du client."""
    limit = utcnow() - timedelta(hours=settings.auto_release_hours)
    due = db.scalars(select(Order).where(Order.status == "delivered",
                                         Order.delivered_at <= limit)).all()
    for o in due:
        complete(db, o, by="auto")
    db.commit()
    return len(due)


def refresh_rating(db: Session, pro_id: str) -> None:
    avg, n = db.execute(select(func.avg(Review.stars), func.count(Review.id))
                        .where(Review.pro_id == pro_id, Review.hidden.is_(False))).one()
    p = db.get(ProProfile, pro_id)
    if p:
        p.rating = float(avg or 0)
        p.reviews_count = int(n or 0)
