from sqlalchemy import JSON, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base, TimestampMixin, new_id
from app.models.user import User


class Service(TimestampMixin, Base):
    __tablename__ = "services"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    category: Mapped[str | None] = mapped_column(String(80))
    price_xaf: Mapped[int] = mapped_column(Integer, default=0)
    pricing_type: Mapped[str] = mapped_column(String(12), default="fixed")  # fixed|from|quote|hourly|monthly
    # Formules : [{"name": "Basic", "price_xaf": 15000}, ...]
    variants: Mapped[list] = mapped_column(JSON, default=list)
    deliverables: Mapped[list] = mapped_column(JSON, default=list)
    images: Mapped[list] = mapped_column(JSON, default=list)
    duration: Mapped[str] = mapped_column(String(60), default="")
    modality: Mapped[str] = mapped_column(String(20), default="À distance")
    cancellation: Mapped[str] = mapped_column(String(20), default="Standard")
    status: Mapped[str] = mapped_column(String(10), default="active", index=True)  # active|draft|paused
    position: Mapped[int] = mapped_column(Integer, default=0)

    pro: Mapped[User] = relationship()

    def price_for(self, variant: str | None) -> int:
        for v in self.variants or []:
            if v.get("name") == variant:
                return int(v.get("price_xaf", self.price_xaf))
        return self.price_xaf


class QuoteRequest(TimestampMixin, Base):
    __tablename__ = "quote_requests"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    client_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    service_id: Mapped[str | None] = mapped_column(ForeignKey("services.id", ondelete="SET NULL"))
    description: Mapped[str] = mapped_column(Text)
    budget: Mapped[str | None] = mapped_column(String(40))
    urgency: Mapped[str | None] = mapped_column(String(20))
    location: Mapped[str | None] = mapped_column(String(200))
    status: Mapped[str] = mapped_column(String(12), default="pending")  # pending|quoted|accepted|declined
    # Réponse du pro : [{"label": "...", "amount_xaf": 50000}]
    lines: Mapped[list] = mapped_column(JSON, default=list)
    total_xaf: Mapped[int] = mapped_column(Integer, default=0)
    delay: Mapped[str | None] = mapped_column(String(60))
    reply_message: Mapped[str | None] = mapped_column(Text)
    order_id: Mapped[str | None] = mapped_column(String(32))

    client: Mapped[User] = relationship(foreign_keys=[client_id])
    pro: Mapped[User] = relationship(foreign_keys=[pro_id])
