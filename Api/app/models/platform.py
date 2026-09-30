from datetime import datetime

from sqlalchemy import JSON, Boolean, ForeignKey, Integer, String, Text
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base, TimestampMixin, new_id


class Notification(TimestampMixin, Base):
    __tablename__ = "notifications"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(16))  # order|live|message|follow|payment|review|system
    title: Mapped[str] = mapped_column(String(200))
    body: Mapped[str] = mapped_column(Text, default="")
    data: Mapped[dict] = mapped_column(JSON, default=dict)
    read: Mapped[bool] = mapped_column(Boolean, default=False, index=True)


class Campaign(TimestampMixin, Base):
    """Sponsorisation d'un post / profil / service (UC-PR-16)."""

    __tablename__ = "campaigns"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    owner_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    target_type: Mapped[str] = mapped_column(String(10))  # post|profile|service
    target_id: Mapped[str | None] = mapped_column(String(32))
    goal: Mapped[str] = mapped_column(String(12), default="visits")  # visits|messages|orders
    cities: Mapped[list] = mapped_column(JSON, default=list)
    interests: Mapped[list] = mapped_column(JSON, default=list)
    daily_budget_xaf: Mapped[int] = mapped_column(Integer)
    days: Mapped[int] = mapped_column(Integer)
    spent_xaf: Mapped[int] = mapped_column(Integer, default=0)
    impressions: Mapped[int] = mapped_column(Integer, default=0)
    clicks: Mapped[int] = mapped_column(Integer, default=0)
    # pending_review|active|paused|rejected|ended
    status: Mapped[str] = mapped_column(String(16), default="pending_review", index=True)
    starts_at: Mapped[datetime | None] = mapped_column()

    @property
    def total_xaf(self) -> int:
        return self.daily_budget_xaf * self.days


class AuditLog(TimestampMixin, Base):
    """Journal d'audit obligatoire pour toute action admin."""

    __tablename__ = "audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    actor_id: Mapped[str] = mapped_column(ForeignKey("users.id"), index=True)
    action: Mapped[str] = mapped_column(String(60), index=True)
    target_type: Mapped[str | None] = mapped_column(String(20))
    target_id: Mapped[str | None] = mapped_column(String(32))
    payload: Mapped[dict] = mapped_column(JSON, default=dict)
    ip: Mapped[str | None] = mapped_column(String(64))


class PlatformSetting(Base):
    """Paramètres modifiables depuis le back-office (commissions, packs, CGU…)."""

    __tablename__ = "platform_settings"

    key: Mapped[str] = mapped_column(String(60), primary_key=True)
    value: Mapped[dict] = mapped_column(JSON)
    updated_at: Mapped[datetime | None] = mapped_column()


class BannedKeyword(TimestampMixin, Base):
    __tablename__ = "banned_keywords"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    word: Mapped[str] = mapped_column(String(80), unique=True)
    note: Mapped[str | None] = mapped_column(Text)
