from sqlalchemy import JSON, ForeignKey, Integer, String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base, TimestampMixin, new_id


class Wallet(Base):
    """Portefeuille interne. `escrow_xaf` = fonds bloqués (acheteur) ou à recevoir (pro)."""

    __tablename__ = "wallets"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    balance_xaf: Mapped[int] = mapped_column(Integer, default=0)
    escrow_xaf: Mapped[int] = mapped_column(Integer, default=0)


class Transaction(TimestampMixin, Base):
    """Écriture du grand livre. `amount_xaf` est signé (+ crédit, − débit)."""

    __tablename__ = "transactions"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    reference: Mapped[str] = mapped_column(String(24), unique=True, index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    # topup|withdraw|order_payment|order_payout|refund|commission|ticket|ticket_payout
    # |tip|tip_payout|sponsorship|subscription|replay
    kind: Mapped[str] = mapped_column(String(20), index=True)
    amount_xaf: Mapped[int] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(12), default="completed")  # pending|completed|failed
    label: Mapped[str] = mapped_column(String(200), default="")
    method: Mapped[str | None] = mapped_column(String(16))  # wallet|mtn|orange|card
    phone: Mapped[str | None] = mapped_column(String(32))
    related_id: Mapped[str | None] = mapped_column(String(32), index=True)
    meta: Mapped[dict] = mapped_column(JSON, default=dict)
