from datetime import datetime

from sqlalchemy import JSON, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base, TimestampMixin, new_id
from app.models.catalog import Service
from app.models.user import User


class Order(TimestampMixin, Base):
    """Commande escrow.

    pending (fonds bloqués) → in_progress (pro confirme) → delivered
    → completed (fonds libérés) ; branches : cancelled (remboursé), disputed.
    """

    __tablename__ = "orders"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    code: Mapped[str] = mapped_column(String(16), unique=True, index=True)
    client_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    service_id: Mapped[str | None] = mapped_column(ForeignKey("services.id", ondelete="SET NULL"))
    title: Mapped[str] = mapped_column(String(200))
    variant: Mapped[str | None] = mapped_column(String(40))
    brief: Mapped[str | None] = mapped_column(Text)
    slot: Mapped[str | None] = mapped_column(String(80))
    amount_xaf: Mapped[int] = mapped_column(Integer)
    commission_xaf: Mapped[int] = mapped_column(Integer, default=0)
    payment_method: Mapped[str] = mapped_column(String(16), default="wallet")
    status: Mapped[str] = mapped_column(String(16), default="pending", index=True)
    deadline: Mapped[datetime | None] = mapped_column()
    confirmed_at: Mapped[datetime | None] = mapped_column()
    delivered_at: Mapped[datetime | None] = mapped_column()
    completed_at: Mapped[datetime | None] = mapped_column()
    cancelled_at: Mapped[datetime | None] = mapped_column()
    deliverables: Mapped[list] = mapped_column(JSON, default=list)
    delivery_message: Mapped[str | None] = mapped_column(Text)

    client: Mapped[User] = relationship(foreign_keys=[client_id])
    pro: Mapped[User] = relationship(foreign_keys=[pro_id])
    service: Mapped[Service | None] = relationship()

    @property
    def net_xaf(self) -> int:
        return self.amount_xaf - self.commission_xaf


class Dispute(TimestampMixin, Base):
    __tablename__ = "disputes"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"), unique=True)
    opened_by: Mapped[str] = mapped_column(ForeignKey("users.id"))
    reason: Mapped[str] = mapped_column(String(200))
    remedy: Mapped[str] = mapped_column(String(16), default="refund")  # refund|partial|redo
    description: Mapped[str | None] = mapped_column(Text)
    evidence: Mapped[list] = mapped_column(JSON, default=list)
    # Historique du dossier : [{"at": iso, "by": user_id, "text": "..."}]
    events: Mapped[list] = mapped_column(JSON, default=list)
    status: Mapped[str] = mapped_column(String(16), default="open", index=True)  # open|resolved
    resolution: Mapped[str | None] = mapped_column(String(20))  # refund|release|split
    refund_xaf: Mapped[int] = mapped_column(Integer, default=0)
    resolved_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    resolved_at: Mapped[datetime | None] = mapped_column()

    order: Mapped[Order] = relationship()


class Review(TimestampMixin, Base):
    __tablename__ = "reviews"
    __table_args__ = (UniqueConstraint("order_id"),)

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    order_id: Mapped[str] = mapped_column(ForeignKey("orders.id", ondelete="CASCADE"))
    author_id: Mapped[str] = mapped_column(ForeignKey("users.id"))
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    stars: Mapped[int] = mapped_column(Integer)
    text: Mapped[str] = mapped_column(Text, default="")
    tags: Mapped[list] = mapped_column(JSON, default=list)
    reply: Mapped[str | None] = mapped_column(Text)
    hidden: Mapped[bool] = mapped_column(default=False)

    author: Mapped[User] = relationship(foreign_keys=[author_id])
