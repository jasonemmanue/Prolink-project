"""Grand livre du portefeuille + séquestre (escrow).

Toutes les opérations verrouillent la ligne `wallets` (SELECT … FOR UPDATE)
pour éviter les doubles dépenses. Le commit est laissé à l'appelant.
"""
import secrets
from datetime import timedelta

from fastapi import HTTPException
from sqlalchemy import func, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.db import utcnow
from app.models import Transaction, User, Wallet

MONEY_KINDS_2FA = ("order_payment", "withdraw", "topup", "ticket", "tip", "subscription", "sponsorship")


def _ref(prefix: str = "TX") -> str:
    return f"{prefix}-{secrets.token_hex(5).upper()}"


def wallet_of(db: Session, user_id: str, lock: bool = False) -> Wallet:
    stmt = select(Wallet).where(Wallet.user_id == user_id)
    if lock:
        stmt = stmt.with_for_update()
    w = db.scalars(stmt).first()
    if not w:
        w = Wallet(user_id=user_id, balance_xaf=0, escrow_xaf=0)
        db.add(w)
        db.flush()
    return w


def record(db: Session, user_id: str, kind: str, amount: int, label: str, *,
           status: str = "completed", method: str | None = None, phone: str | None = None,
           related_id: str | None = None, meta: dict | None = None, prefix: str = "TX") -> Transaction:
    tx = Transaction(reference=_ref(prefix), user_id=user_id, kind=kind, amount_xaf=amount,
                     status=status, label=label, method=method, phone=phone,
                     related_id=related_id, meta=meta or {})
    db.add(tx)
    return tx


def credit(db: Session, user_id: str, amount: int, kind: str, label: str, **kw) -> Transaction:
    w = wallet_of(db, user_id, lock=True)
    w.balance_xaf += amount
    return record(db, user_id, kind, amount, label, **kw)


def debit(db: Session, user_id: str, amount: int, kind: str, label: str, **kw) -> Transaction:
    if amount <= 0:
        raise HTTPException(400, "Montant invalide")
    w = wallet_of(db, user_id, lock=True)
    if w.balance_xaf < amount:
        raise HTTPException(402, f"Solde insuffisant ({w.balance_xaf} XAF disponibles)")
    w.balance_xaf -= amount
    return record(db, user_id, kind, -amount, label, **kw)


def monthly_volume(db: Session, user_id: str) -> int:
    since = utcnow() - timedelta(days=30)
    total = db.scalar(
        select(func.coalesce(func.sum(func.abs(Transaction.amount_xaf)), 0)).where(
            Transaction.user_id == user_id,
            Transaction.kind.in_(MONEY_KINDS_2FA),
            Transaction.status == "completed",
            Transaction.created_at >= since,
        )
    )
    return int(total or 0)


def require_2fa_if_needed(db: Session, user: User, upcoming: int) -> None:
    """2FA obligatoire au-delà de 100 000 XAF de transactions sur 30 jours."""
    if user.two_fa_enabled:
        return
    if monthly_volume(db, user.id) + upcoming > settings.two_fa_monthly_threshold_xaf:
        raise HTTPException(
            403,
            "Double authentification requise : plus de "
            f"{settings.two_fa_monthly_threshold_xaf} XAF de transactions sur 30 jours. "
            "Activez la 2FA dans Sécurité.",
        )


# ---------- Séquestre des commandes ----------

def hold_order_funds(db: Session, client_id: str, pro_id: str, amount: int, net: int,
                     order_id: str, label: str, method: str) -> None:
    """Débite l'acheteur et bloque les fonds (escrow acheteur + à recevoir pro)."""
    debit(db, client_id, amount, "order_payment", label, method=method, related_id=order_id)
    wallet_of(db, client_id, lock=True).escrow_xaf += amount
    wallet_of(db, pro_id, lock=True).escrow_xaf += net


def release_order_funds(db: Session, client_id: str, pro_id: str, amount: int,
                        commission: int, order_id: str, label: str) -> None:
    """Libère le séquestre au pro : brut crédité puis commission prélevée."""
    net = amount - commission
    wallet_of(db, client_id, lock=True).escrow_xaf -= amount
    wallet_of(db, pro_id, lock=True).escrow_xaf -= net
    credit(db, pro_id, amount, "order_payout", label, related_id=order_id)
    if commission:
        debit(db, pro_id, commission, "commission", f"Commission ProLink — {label}", related_id=order_id)


def refund_order_funds(db: Session, client_id: str, pro_id: str, amount: int, net: int,
                       order_id: str, label: str, refund: int | None = None,
                       commission: int = 0) -> None:
    """Rembourse tout (refund=None) ou partiellement ; le reste est versé au pro."""
    refund = amount if refund is None else refund
    wallet_of(db, client_id, lock=True).escrow_xaf -= amount
    wallet_of(db, pro_id, lock=True).escrow_xaf -= net
    if refund:
        credit(db, client_id, refund, "refund", f"Remboursement — {label}", related_id=order_id)
    rest = amount - refund
    if rest > 0:
        credit(db, pro_id, rest, "order_payout", label, related_id=order_id)
        if commission:
            debit(db, pro_id, commission, "commission", f"Commission ProLink — {label}", related_id=order_id)
