"""Schémas Pydantic (entrées/sorties) + constructeurs depuis les modèles ORM."""
from datetime import datetime
from typing import Literal

from pydantic import BaseModel, ConfigDict, EmailStr, Field

from app.models import (
    Campaign, Dispute, Live, Message, Notification, Order, Post,
    PostComment, ProProfile, QuoteRequest, Review, Service, Transaction, User, Wallet,
)
from app.core.config import settings


class ORM(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ---------------------------------------------------------------- utilisateurs

class UserPublic(ORM):
    id: str
    name: str
    avatar_url: str | None = None
    city: str | None = None
    role: str
    job: str | None = None
    verified_level: int = 0


def user_public(u: User) -> UserPublic:
    return UserPublic(
        id=u.id, name=u.name, avatar_url=u.avatar_url, city=u.city, role=u.role,
        job=u.pro.job if u.pro else None,
        verified_level=u.pro.verified_level if u.pro else 0,
    )


class ProOut(ORM):
    id: str
    name: str
    avatar_url: str | None
    cover_url: str | None
    job: str
    category: str | None
    secondary_categories: list[str] = []
    city: str | None
    bio: str
    service_area: str | None
    languages: list[str]
    rating: float
    reviews_count: int
    followers_count: int
    verified_level: int
    kyc_status: str
    plan: str
    is_following: bool = False
    notify: bool = False


def pro_out(u: User, follow=None) -> ProOut:
    p: ProProfile = u.pro
    return ProOut(
        id=u.id, name=u.name, avatar_url=u.avatar_url, cover_url=p.cover_url, job=p.job,
        category=p.category.name if p.category else None,
        secondary_categories=p.secondary_categories or [], city=u.city, bio=p.bio,
        service_area=p.service_area, languages=u.languages or [], rating=round(p.rating, 2),
        reviews_count=p.reviews_count, followers_count=p.followers_count,
        verified_level=p.verified_level, kyc_status=p.kyc_status, plan=p.plan,
        is_following=follow is not None, notify=bool(follow and follow.notify),
    )


class MeOut(ORM):
    id: str
    name: str
    email: str | None
    phone: str | None
    role: str
    city: str | None
    address: str | None
    avatar_url: str | None
    languages: list[str]
    ui_lang: str
    two_fa_enabled: bool
    phone_verified: bool
    notification_prefs: dict
    created_at: datetime
    pro: ProOut | None = None


def me_out(u: User) -> MeOut:
    return MeOut(
        id=u.id, name=u.name, email=u.email, phone=u.phone, role=u.role, city=u.city,
        address=u.address, avatar_url=u.avatar_url, languages=u.languages or [],
        ui_lang=u.ui_lang, two_fa_enabled=u.two_fa_enabled, phone_verified=u.phone_verified,
        notification_prefs=u.notification_prefs or {}, created_at=u.created_at,
        pro=pro_out(u) if u.pro else None,
    )


class RegisterIn(BaseModel):
    name: str = Field(min_length=2, max_length=120)
    email: EmailStr | None = None
    phone: str | None = Field(default=None, max_length=32)
    password: str = Field(min_length=8, max_length=128)
    role: Literal["client", "pro"] = "client"
    city: str | None = None
    # Champs pro (si role == "pro")
    job: str | None = None
    category: str | None = None


class LoginIn(BaseModel):
    login: str = Field(description="E-mail ou téléphone")
    password: str
    otp: str | None = Field(default=None, description="Code 2FA si activée")


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"
    user: MeOut


class RefreshIn(BaseModel):
    refresh_token: str


class MeUpdate(BaseModel):
    name: str | None = None
    city: str | None = None
    address: str | None = None
    avatar_url: str | None = None
    languages: list[str] | None = None
    ui_lang: Literal["fr", "en"] | None = None
    notification_prefs: dict | None = None


class PasswordChange(BaseModel):
    current_password: str
    new_password: str = Field(min_length=8, max_length=128)


class OtpSendIn(BaseModel):
    target: str = Field(description="Téléphone (login/verify_phone) — ignoré pour 2fa/withdraw")
    purpose: Literal["login", "verify_phone", "2fa", "withdraw"] = "verify_phone"


class OtpVerifyIn(BaseModel):
    target: str
    purpose: Literal["login", "verify_phone", "2fa", "withdraw"] = "verify_phone"
    code: str


class ProUpsert(BaseModel):
    job: str | None = None
    category: str | None = None
    secondary_categories: list[str] | None = Field(default=None, max_length=2)
    bio: str | None = None
    cover_url: str | None = None
    service_area: str | None = None


# --------------------------------------------------------------------- social

class PostIn(BaseModel):
    kind: Literal["text", "photo", "video", "article", "portfolio", "poll", "event", "live_announce"] = "text"
    title: str | None = None
    text: str = Field(min_length=1, max_length=3000)
    images: list[str] = Field(default_factory=list, max_length=10)
    audience: Literal["public", "followers"] = "public"
    scheduled_at: datetime | None = None


class PostUpdate(BaseModel):
    title: str | None = None
    text: str | None = Field(default=None, max_length=3000)
    images: list[str] | None = Field(default=None, max_length=10)
    audience: Literal["public", "followers"] | None = None


class PostOut(ORM):
    id: str
    author: UserPublic
    kind: str
    title: str | None
    text: str
    images: list[str]
    audience: str
    sponsored: bool
    likes_count: int
    comments_count: int
    liked: bool = False
    saved: bool = False
    scheduled_at: datetime | None
    created_at: datetime


def post_out(p: Post, liked: bool = False, saved: bool = False) -> PostOut:
    return PostOut(
        id=p.id, author=user_public(p.author), kind=p.kind, title=p.title, text=p.text,
        images=p.images or [], audience=p.audience, sponsored=p.sponsored,
        likes_count=p.likes_count, comments_count=p.comments_count, liked=liked, saved=saved,
        scheduled_at=p.scheduled_at, created_at=p.created_at,
    )


class CommentIn(BaseModel):
    text: str = Field(min_length=1, max_length=1000)


class CommentOut(ORM):
    id: str
    author: UserPublic
    text: str
    created_at: datetime


def comment_out(c: PostComment) -> CommentOut:
    return CommentOut(id=c.id, author=user_public(c.author), text=c.text, created_at=c.created_at)


class ReportIn(BaseModel):
    target_type: Literal["post", "comment", "pro", "user", "live", "group", "review", "message"]
    target_id: str
    reason: str = Field(min_length=2, max_length=200)
    details: str | None = None


class ReportOut(ORM):
    id: str
    reporter_id: str
    target_type: str
    target_id: str
    reason: str
    details: str | None
    status: str
    created_at: datetime


# -------------------------------------------------------------------- catalogue

class Variant(BaseModel):
    name: str
    price_xaf: int = Field(ge=0)
    description: str | None = None


class ServiceIn(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = ""
    category: str | None = None
    price_xaf: int = Field(0, ge=0)
    pricing_type: Literal["fixed", "from", "quote", "hourly", "monthly"] = "fixed"
    variants: list[Variant] = []
    deliverables: list[str] = []
    images: list[str] = []
    duration: str = ""
    modality: str = "À distance"
    cancellation: Literal["Flexible", "Standard", "Stricte"] = "Standard"
    status: Literal["active", "draft", "paused"] = "active"


class ServiceUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    category: str | None = None
    price_xaf: int | None = Field(default=None, ge=0)
    pricing_type: Literal["fixed", "from", "quote", "hourly", "monthly"] | None = None
    variants: list[Variant] | None = None
    deliverables: list[str] | None = None
    images: list[str] | None = None
    duration: str | None = None
    modality: str | None = None
    cancellation: Literal["Flexible", "Standard", "Stricte"] | None = None
    status: Literal["active", "draft", "paused"] | None = None


class ServiceOut(ORM):
    id: str
    pro_id: str
    title: str
    description: str
    category: str | None
    price_xaf: int
    pricing_type: str
    variants: list[dict]
    deliverables: list[str]
    images: list[str]
    duration: str
    modality: str
    cancellation: str
    status: str
    position: int
    created_at: datetime


class ReorderIn(BaseModel):
    ids: list[str]


class QuoteIn(BaseModel):
    pro_id: str
    service_id: str | None = None
    description: str = Field(min_length=10, max_length=4000)
    budget: str | None = None
    urgency: str | None = None
    location: str | None = None


class QuoteLine(BaseModel):
    label: str
    amount_xaf: int = Field(ge=0)


class QuoteReplyIn(BaseModel):
    lines: list[QuoteLine] = Field(min_length=1)
    delay: str | None = None
    message: str | None = None


class QuoteOut(ORM):
    id: str
    client: UserPublic
    pro: UserPublic
    service_id: str | None
    description: str
    budget: str | None
    urgency: str | None
    location: str | None
    status: str
    lines: list[dict]
    total_xaf: int
    delay: str | None
    reply_message: str | None
    order_id: str | None
    created_at: datetime


def quote_out(q: QuoteRequest) -> QuoteOut:
    return QuoteOut(
        id=q.id, client=user_public(q.client), pro=user_public(q.pro), service_id=q.service_id,
        description=q.description, budget=q.budget, urgency=q.urgency, location=q.location,
        status=q.status, lines=q.lines or [], total_xaf=q.total_xaf, delay=q.delay,
        reply_message=q.reply_message, order_id=q.order_id, created_at=q.created_at,
    )


# --------------------------------------------------------------------- commandes

PaymentMethod = Literal["wallet", "mtn", "orange", "card"]


class OrderIn(BaseModel):
    service_id: str
    variant: str | None = None
    brief: str | None = None
    slot: str | None = None
    payment_method: PaymentMethod = "wallet"
    phone: str | None = None


class DeliverIn(BaseModel):
    message: str | None = None
    deliverables: list[str] = []


class DisputeIn(BaseModel):
    reason: str = Field(min_length=3, max_length=200)
    remedy: Literal["refund", "partial", "redo"] = "refund"
    description: str | None = None
    evidence: list[str] = []


class DisputeMessageIn(BaseModel):
    text: str = Field(min_length=1, max_length=2000)


class DisputeOut(ORM):
    id: str
    order_id: str
    opened_by: str
    reason: str
    remedy: str
    description: str | None
    evidence: list[str]
    events: list[dict]
    status: str
    resolution: str | None
    refund_xaf: int
    created_at: datetime
    resolved_at: datetime | None


class OrderOut(ORM):
    id: str
    code: str
    title: str
    variant: str | None
    brief: str | None
    slot: str | None
    amount_xaf: int
    commission_xaf: int
    net_xaf: int
    payment_method: str
    status: str
    escrow_status: str
    deadline: datetime | None
    created_at: datetime
    confirmed_at: datetime | None
    delivered_at: datetime | None
    completed_at: datetime | None
    auto_release_at: datetime | None
    delivery_message: str | None
    deliverables: list[str]
    service_id: str | None
    client: UserPublic
    pro: UserPublic
    reviewed: bool = False


def order_out(o: Order, reviewed: bool = False) -> OrderOut:
    from datetime import timedelta

    escrow = {
        "completed": "released", "cancelled": "refunded", "disputed": "frozen",
    }.get(o.status, "held")
    auto = (o.delivered_at + timedelta(hours=settings.auto_release_hours)
            if o.status == "delivered" and o.delivered_at else None)
    return OrderOut(
        id=o.id, code=o.code, title=o.title, variant=o.variant, brief=o.brief, slot=o.slot,
        amount_xaf=o.amount_xaf, commission_xaf=o.commission_xaf, net_xaf=o.net_xaf,
        payment_method=o.payment_method, status=o.status, escrow_status=escrow,
        deadline=o.deadline, created_at=o.created_at, confirmed_at=o.confirmed_at,
        delivered_at=o.delivered_at, completed_at=o.completed_at, auto_release_at=auto,
        delivery_message=o.delivery_message, deliverables=o.deliverables or [],
        service_id=o.service_id, client=user_public(o.client), pro=user_public(o.pro),
        reviewed=reviewed,
    )


class ReviewIn(BaseModel):
    stars: int = Field(ge=1, le=5)
    text: str = Field("", max_length=2000)
    tags: list[str] = []


class ReviewReplyIn(BaseModel):
    reply: str = Field(min_length=1, max_length=2000)


class ReviewOut(ORM):
    id: str
    order_id: str
    pro_id: str
    author: UserPublic
    stars: int
    text: str
    tags: list[str]
    reply: str | None
    created_at: datetime


def review_out(r: Review) -> ReviewOut:
    return ReviewOut(id=r.id, order_id=r.order_id, pro_id=r.pro_id, author=user_public(r.author),
                     stars=r.stars, text=r.text, tags=r.tags or [], reply=r.reply,
                     created_at=r.created_at)


# ------------------------------------------------------------------ portefeuille

class WalletOut(BaseModel):
    balance_xaf: int
    escrow_xaf: int
    withdrawable_xaf: int
    currency: str = "XAF"
    monthly_volume_xaf: int
    two_fa_required: bool


class TopUpIn(BaseModel):
    amount_xaf: int = Field(ge=100, le=5_000_000)
    method: Literal["mtn", "orange", "card"]
    phone: str | None = None


class WithdrawIn(BaseModel):
    amount_xaf: int = Field(ge=1)
    operator: Literal["mtn", "orange"]
    phone: str
    otp: str = Field(description="Code reçu via /auth/otp/send (purpose=withdraw)")


class TxOut(ORM):
    id: str
    reference: str
    kind: str
    amount_xaf: int
    status: str
    label: str
    method: str | None
    related_id: str | None
    created_at: datetime


def wallet_out(w: Wallet, monthly: int, two_fa: bool) -> WalletOut:
    return WalletOut(
        balance_xaf=w.balance_xaf, escrow_xaf=w.escrow_xaf,
        withdrawable_xaf=max(0, w.balance_xaf - settings.wallet_min_balance_xaf),
        monthly_volume_xaf=monthly,
        two_fa_required=(not two_fa) and monthly > settings.two_fa_monthly_threshold_xaf,
    )


# ------------------------------------------------------------------------- chat

class DirectIn(BaseModel):
    user_id: str


class GroupIn(BaseModel):
    title: str = Field(min_length=3, max_length=160)
    description: str | None = None
    access: Literal["public", "private", "paid"] = "public"
    price_xaf: int = Field(0, ge=0)
    only_host_posts: bool = False


class MessageIn(BaseModel):
    text: str = Field("", max_length=4000)
    attachments: list[dict] = []


class MessageOut(ORM):
    id: str
    conversation_id: str
    author_id: str
    text: str
    lang: str | None
    attachments: list[dict]
    created_at: datetime


class ConversationOut(BaseModel):
    id: str
    kind: str
    title: str
    avatar_url: str | None
    peer: UserPublic | None = None
    host: UserPublic | None = None
    description: str | None = None
    access: str
    price_xaf: int
    members_count: int
    my_status: str | None = None
    last_message: MessageOut | None = None
    unread: int = 0
    archived: bool = False
    pinned: bool = False
    online: bool = False


class MemberPrefsIn(BaseModel):
    archived: bool | None = None
    pinned: bool | None = None
    muted: bool | None = None


# ------------------------------------------------------------------------ lives

class LiveIn(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    description: str = ""
    cover_url: str | None = None
    mode: Literal["free", "followers", "paid", "tips"] = "free"
    price_xaf: int = Field(0, ge=0)
    scheduled_at: datetime | None = None


class LiveUpdate(BaseModel):
    title: str | None = None
    description: str | None = None
    cover_url: str | None = None
    scheduled_at: datetime | None = None
    price_xaf: int | None = Field(default=None, ge=0)


class LiveEndIn(BaseModel):
    replay_policy: Literal["free", "paid", "private", "none"] = "free"
    replay_price_xaf: int = Field(0, ge=0)


class TipIn(BaseModel):
    amount_xaf: int = Field(ge=100, le=500_000)


class LiveOut(BaseModel):
    id: str
    pro: UserPublic
    title: str
    description: str
    cover_url: str | None
    mode: str
    paying: bool
    price_xaf: int
    status: str
    scheduled_at: datetime | None
    started_at: datetime | None
    ended_at: datetime | None
    viewers: int
    peak_viewers: int
    tips_xaf: int
    replay_policy: str
    replay_price_xaf: int
    has_access: bool = False


def live_out(lv: Live, has_access: bool = False) -> LiveOut:
    return LiveOut(
        id=lv.id, pro=user_public(lv.pro), title=lv.title, description=lv.description,
        cover_url=lv.cover_url, mode=lv.mode, paying=lv.paying, price_xaf=lv.price_xaf,
        status=lv.status, scheduled_at=lv.scheduled_at, started_at=lv.started_at,
        ended_at=lv.ended_at, viewers=lv.viewers, peak_viewers=lv.peak_viewers,
        tips_xaf=lv.tips_xaf, replay_policy=lv.replay_policy,
        replay_price_xaf=lv.replay_price_xaf, has_access=has_access,
    )


# -------------------------------------------------------------- notifications

class NotificationOut(ORM):
    id: str
    kind: str
    title: str
    body: str
    data: dict
    read: bool
    created_at: datetime


class DeviceTokenIn(BaseModel):
    token: str = Field(min_length=10, max_length=400)
    platform: Literal["android", "ios", "web"] = "android"


# ---------------------------------------------------------- sponsorisation / packs

class CampaignIn(BaseModel):
    target_type: Literal["post", "profile", "service"]
    target_id: str | None = None
    goal: Literal["visits", "messages", "orders"] = "visits"
    cities: list[str] = []
    interests: list[str] = []
    daily_budget_xaf: int = Field(ge=1000, le=50_000)
    days: int = Field(ge=1, le=30)


class CampaignOut(ORM):
    id: str
    owner_id: str
    target_type: str
    target_id: str | None
    goal: str
    cities: list[str]
    interests: list[str]
    daily_budget_xaf: int
    days: int
    total_xaf: int
    spent_xaf: int
    impressions: int
    clicks: int
    status: str
    starts_at: datetime | None
    created_at: datetime


class SubscribeIn(BaseModel):
    plan: Literal["premium", "business"]
    months: int = Field(1, ge=1, le=12)


class KycDocIn(BaseModel):
    kind: Literal["id_card", "selfie", "address", "registry", "diploma"]
    file_url: str = Field(min_length=5, max_length=500)


class KycDocOut(ORM):
    id: str
    kind: str
    file_url: str
    status: str
    note: str | None
    created_at: datetime


class CategoryOut(ORM):
    id: int
    name: str
    parent_id: int | None
    position: int
    active: bool


class TranslateIn(BaseModel):
    text: str
    source: str = "auto"
    target: Literal["fr", "en"]


class TranslateOut(BaseModel):
    text: str
    detected_source: str
    provider: str


def campaign_out(c: Campaign) -> CampaignOut:
    return CampaignOut.model_validate(c)


def notification_out(n: Notification) -> NotificationOut:
    return NotificationOut.model_validate(n)


def message_out(m: Message) -> MessageOut:
    return MessageOut.model_validate(m)


def dispute_out(d: Dispute) -> DisputeOut:
    return DisputeOut.model_validate(d)


def service_out(s: Service) -> ServiceOut:
    return ServiceOut.model_validate(s)


def tx_out(t: Transaction) -> TxOut:
    return TxOut.model_validate(t)

