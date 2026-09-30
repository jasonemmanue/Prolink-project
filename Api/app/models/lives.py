from datetime import datetime

from sqlalchemy import ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base, TimestampMixin, new_id
from app.models.user import User


class Live(TimestampMixin, Base):
    __tablename__ = "lives"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    title: Mapped[str] = mapped_column(String(200))
    description: Mapped[str] = mapped_column(Text, default="")
    cover_url: Mapped[str | None] = mapped_column(String(500))
    mode: Mapped[str] = mapped_column(String(10), default="free")  # free|followers|paid|tips
    price_xaf: Mapped[int] = mapped_column(Integer, default=0)
    status: Mapped[str] = mapped_column(String(10), default="scheduled", index=True)  # scheduled|live|ended|cut
    scheduled_at: Mapped[datetime | None] = mapped_column()
    started_at: Mapped[datetime | None] = mapped_column()
    ended_at: Mapped[datetime | None] = mapped_column()
    viewers: Mapped[int] = mapped_column(Integer, default=0)
    peak_viewers: Mapped[int] = mapped_column(Integer, default=0)
    tips_xaf: Mapped[int] = mapped_column(Integer, default=0)
    replay_policy: Mapped[str] = mapped_column(String(10), default="free")  # free|paid|private|none
    replay_price_xaf: Mapped[int] = mapped_column(Integer, default=0)
    replay_url: Mapped[str | None] = mapped_column(String(500))

    pro: Mapped[User] = relationship()

    @property
    def paying(self) -> bool:
        return self.mode == "paid"


class LiveTicket(TimestampMixin, Base):
    __tablename__ = "live_tickets"
    __table_args__ = (UniqueConstraint("live_id", "user_id", "kind"),)

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    live_id: Mapped[str] = mapped_column(ForeignKey("lives.id", ondelete="CASCADE"), index=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(8), default="live")  # live|replay
    price_xaf: Mapped[int] = mapped_column(Integer, default=0)
