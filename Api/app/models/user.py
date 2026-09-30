from datetime import datetime

from sqlalchemy import JSON, Boolean, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.db import Base, TimestampMixin, new_id, utcnow


class User(TimestampMixin, Base):
    __tablename__ = "users"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    name: Mapped[str] = mapped_column(String(120))
    email: Mapped[str | None] = mapped_column(String(180), unique=True, index=True)
    phone: Mapped[str | None] = mapped_column(String(32), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    role: Mapped[str] = mapped_column(String(16), default="client", index=True)  # client|pro|admin
    city: Mapped[str | None] = mapped_column(String(80))
    address: Mapped[str | None] = mapped_column(String(200))
    avatar_url: Mapped[str | None] = mapped_column(String(500))
    languages: Mapped[list] = mapped_column(JSON, default=lambda: ["FR"])
    ui_lang: Mapped[str] = mapped_column(String(2), default="fr")
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)
    two_fa_enabled: Mapped[bool] = mapped_column(Boolean, default=False)
    phone_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    notification_prefs: Mapped[dict] = mapped_column(JSON, default=dict)

    pro: Mapped["ProProfile | None"] = relationship(back_populates="user", uselist=False)


class Category(Base):
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(80), unique=True)
    parent_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))
    position: Mapped[int] = mapped_column(Integer, default=0)
    active: Mapped[bool] = mapped_column(Boolean, default=True)


class ProProfile(Base):
    __tablename__ = "pro_profiles"

    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), primary_key=True)
    job: Mapped[str] = mapped_column(String(120))
    category_id: Mapped[int | None] = mapped_column(ForeignKey("categories.id"))
    secondary_categories: Mapped[list] = mapped_column(JSON, default=list)
    bio: Mapped[str] = mapped_column(Text, default="")
    cover_url: Mapped[str | None] = mapped_column(String(500))
    service_area: Mapped[str | None] = mapped_column(String(200))
    rating: Mapped[float] = mapped_column(default=0.0)
    reviews_count: Mapped[int] = mapped_column(Integer, default=0)
    followers_count: Mapped[int] = mapped_column(Integer, default=0)
    verified_level: Mapped[int] = mapped_column(Integer, default=0)  # 0..3 (bleu/or/violet)
    kyc_status: Mapped[str] = mapped_column(String(16), default="none")  # none|pending|approved|rejected
    plan: Mapped[str] = mapped_column(String(16), default="free")  # free|premium|business
    plan_until: Mapped[datetime | None] = mapped_column()

    user: Mapped[User] = relationship(back_populates="pro")
    category: Mapped[Category | None] = relationship()


class KycDocument(TimestampMixin, Base):
    __tablename__ = "kyc_documents"

    id: Mapped[str] = mapped_column(String(32), primary_key=True, default=new_id)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    kind: Mapped[str] = mapped_column(String(40))  # id_card|selfie|address|registry|diploma
    file_url: Mapped[str] = mapped_column(String(500))
    status: Mapped[str] = mapped_column(String(16), default="pending")  # pending|approved|rejected
    reviewed_by: Mapped[str | None] = mapped_column(ForeignKey("users.id"))
    reviewed_at: Mapped[datetime | None] = mapped_column()
    note: Mapped[str | None] = mapped_column(String(300))


class Follow(TimestampMixin, Base):
    __tablename__ = "follows"
    __table_args__ = (UniqueConstraint("follower_id", "pro_id"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    follower_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    pro_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    notify: Mapped[bool] = mapped_column(Boolean, default=False)  # cloche


class OtpCode(Base):
    __tablename__ = "otp_codes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    target: Mapped[str] = mapped_column(String(180), index=True)  # téléphone ou user_id
    purpose: Mapped[str] = mapped_column(String(24))  # login|verify_phone|2fa|withdraw
    code_hash: Mapped[str] = mapped_column(String(255))
    expires_at: Mapped[datetime] = mapped_column()
    used: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(default=utcnow)


class DeviceToken(TimestampMixin, Base):
    __tablename__ = "device_tokens"
    __table_args__ = (UniqueConstraint("token"),)

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    user_id: Mapped[str] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), index=True)
    token: Mapped[str] = mapped_column(String(400))
    platform: Mapped[str] = mapped_column(String(16), default="android")
