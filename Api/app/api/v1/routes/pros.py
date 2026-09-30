from datetime import timedelta

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import case, func, or_, select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import Page, current_user, optional_user, require_pro
from app.db import get_db, utcnow
from app.models import (
    Category, Follow, KycDocument, Live, Order, Post, ProProfile, QuoteRequest, Review,
    Service, Transaction, User,
)
from app.schemas import (
    CategoryOut, KycDocIn, KycDocOut, LiveOut, PostOut, ProOut, ProUpsert, ReviewOut,
    ServiceOut, SubscribeIn, live_out, post_out, pro_out, review_out, service_out,
)
from app.services import cache, ledger
from app.services.notify import notify
from app.services.platform import get_setting

router = APIRouter(tags=["pros"])

# Les packs payants remontent en tête des résultats « pertinence ».
_PLAN_RANK = case((ProProfile.plan == "business", 2), (ProProfile.plan == "premium", 1), else_=0)


def _pro_or_404(db: Session, pro_id: str) -> User:
    u = db.get(User, pro_id)
    if not u or not u.pro or not u.is_active:
        raise HTTPException(404, "Professionnel introuvable")
    return u


def _follow(db: Session, user: User | None, pro_id: str) -> Follow | None:
    if not user:
        return None
    return db.scalars(select(Follow).where(Follow.follower_id == user.id,
                                           Follow.pro_id == pro_id)).first()


# ------------------------------------------------------------------ catégories

@router.get("/categories", response_model=list[CategoryOut], tags=["categories"])
def categories(db: Session = Depends(get_db)):
    return cache.cached("categories", "active", 3600, lambda: [
        CategoryOut.model_validate(c) for c in db.scalars(
            select(Category).where(Category.active.is_(True)).order_by(Category.position, Category.name))
    ])


def _with_follow(db: Session, user: User | None, items: list[dict]) -> list[dict]:
    """Superpose les infos propres à l'utilisateur (suivi, cloche) aux données en cache."""
    if not user or not items:
        return items
    follows = {f.pro_id: f for f in db.scalars(select(Follow).where(
        Follow.follower_id == user.id, Follow.pro_id.in_([p["id"] for p in items])))}
    return [{**p, "is_following": p["id"] in follows,
             "notify": bool(follows.get(p["id"]) and follows[p["id"]].notify)} for p in items]


# ------------------------------------------------------------------ annuaire

@router.get("/pros", response_model=list[ProOut])
def list_pros(
    q: str | None = None,
    category: str | None = None,
    city: str | None = None,
    min_rating: float | None = Query(None, ge=0, le=5),
    verified_only: bool = False,
    language: str | None = None,
    sort: str = Query("relevance", pattern="^(relevance|rating|followers|new)$"),
    page: Page = Depends(),
    db: Session = Depends(get_db),
    user: User | None = Depends(optional_user),
):
    key = f"list:{q}:{category}:{city}:{min_rating}:{verified_only}:{language}:{sort}:{page.limit}:{page.offset}"
    items = cache.cached("pros", key, settings.cache_ttl_seconds, lambda: _search_pros(
        db, q, category, city, min_rating, verified_only, language, sort, page))
    return _with_follow(db, user, items)


def _search_pros(db, q, category, city, min_rating, verified_only, language, sort, page) -> list[ProOut]:
    stmt = (select(User).join(ProProfile).outerjoin(Category, ProProfile.category_id == Category.id)
            .where(User.is_active.is_(True)))
    if q:
        like = f"%{q.lower()}%"
        stmt = stmt.where(or_(func.lower(User.name).like(like), func.lower(ProProfile.job).like(like),
                              func.lower(ProProfile.bio).like(like), func.lower(Category.name).like(like)))
    if category:
        stmt = stmt.where(Category.name == category)
    if city:
        stmt = stmt.where(func.lower(User.city) == city.lower())
    if min_rating is not None:
        stmt = stmt.where(ProProfile.rating >= min_rating)
    if verified_only:
        stmt = stmt.where(ProProfile.verified_level > 0)
    order = {
        "rating": [ProProfile.rating.desc()],
        "followers": [ProProfile.followers_count.desc()],
        "new": [User.created_at.desc()],
    }.get(sort, [_PLAN_RANK.desc(), ProProfile.verified_level.desc(), ProProfile.rating.desc()])
    users = db.scalars(stmt.order_by(*order).limit(page.limit).offset(page.offset)).all()
    if language:
        users = [u for u in users if language.upper() in (u.languages or [])]
    return [pro_out(u) for u in users]


@router.get("/pros/{pro_id}", response_model=ProOut)
def get_pro(pro_id: str, db: Session = Depends(get_db), user: User | None = Depends(optional_user)):
    item = cache.cached("pros", f"one:{pro_id}", settings.cache_ttl_seconds,
                        lambda: pro_out(_pro_or_404(db, pro_id)))
    return _with_follow(db, user, [item])[0]


@router.get("/pros/{pro_id}/services", response_model=list[ServiceOut])
def pro_services(pro_id: str, db: Session = Depends(get_db), user: User | None = Depends(optional_user)):
    _pro_or_404(db, pro_id)
    owner = bool(user and user.id == pro_id)

    def compute():
        stmt = select(Service).where(Service.pro_id == pro_id)
        if not owner:
            stmt = stmt.where(Service.status == "active")
        return [service_out(s) for s in db.scalars(stmt.order_by(Service.position, Service.created_at))]
    return compute() if owner else cache.cached("services", f"pro:{pro_id}", settings.cache_ttl_seconds, compute)


@router.get("/pros/{pro_id}/posts", response_model=list[PostOut])
def pro_posts(pro_id: str, page: Page = Depends(), db: Session = Depends(get_db)):
    _pro_or_404(db, pro_id)
    posts = db.scalars(select(Post).where(Post.author_id == pro_id, Post.hidden.is_(False),
                                          or_(Post.scheduled_at.is_(None), Post.scheduled_at <= utcnow()))
                       .order_by(Post.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [post_out(p) for p in posts]


@router.get("/pros/{pro_id}/portfolio", response_model=list[PostOut])
def pro_portfolio(pro_id: str, db: Session = Depends(get_db)):
    _pro_or_404(db, pro_id)
    posts = db.scalars(select(Post).where(Post.author_id == pro_id, Post.kind == "portfolio",
                                          Post.hidden.is_(False)).order_by(Post.created_at.desc())).all()
    return [post_out(p) for p in posts]


@router.get("/pros/{pro_id}/reviews", response_model=list[ReviewOut])
def pro_reviews(pro_id: str, page: Page = Depends(), db: Session = Depends(get_db)):
    _pro_or_404(db, pro_id)
    rows = db.scalars(select(Review).where(Review.pro_id == pro_id, Review.hidden.is_(False))
                      .order_by(Review.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [review_out(r) for r in rows]


@router.get("/pros/{pro_id}/lives", response_model=list[LiveOut])
def pro_lives(pro_id: str, db: Session = Depends(get_db)):
    _pro_or_404(db, pro_id)
    rows = db.scalars(select(Live).where(Live.pro_id == pro_id).order_by(Live.scheduled_at.desc())).all()
    return [live_out(lv) for lv in rows]


# ------------------------------------------------------------------ abonnement

@router.post("/pros/{pro_id}/follow", response_model=ProOut)
def follow(pro_id: str, notify_bell: bool = Query(False, alias="notify"),
           db: Session = Depends(get_db), user: User = Depends(current_user)):
    u = _pro_or_404(db, pro_id)
    if u.id == user.id:
        raise HTTPException(400, "Impossible de vous suivre vous-même")
    f = _follow(db, user, pro_id)
    if not f:
        f = Follow(follower_id=user.id, pro_id=pro_id, notify=notify_bell)
        db.add(f)
        u.pro.followers_count += 1
        notify(db, pro_id, "follow", "Nouvel abonné", f"{user.name} vous suit désormais.",
               {"user_id": user.id})
    else:
        f.notify = notify_bell
    db.commit()
    cache.invalidate("pros")
    return pro_out(u, f)


@router.delete("/pros/{pro_id}/follow", response_model=ProOut)
def unfollow(pro_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    u = _pro_or_404(db, pro_id)
    f = _follow(db, user, pro_id)
    if f:
        db.delete(f)
        u.pro.followers_count = max(0, u.pro.followers_count - 1)
        db.commit()
        cache.invalidate("pros")
    return pro_out(u, None)


@router.get("/me/following", response_model=list[ProOut], tags=["me"])
def my_following(db: Session = Depends(get_db), user: User = Depends(current_user)):
    rows = db.scalars(select(Follow).where(Follow.follower_id == user.id)).all()
    return [pro_out(db.get(User, f.pro_id), f) for f in rows]


# ------------------------------------------------------------ espace pro (moi)

@router.post("/pros/me", response_model=ProOut, status_code=201)
def become_pro(payload: ProUpsert, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Transforme un compte internaute en compte pro (« Devenir professionnel »)."""
    if user.pro:
        raise HTTPException(409, "Profil pro déjà créé")
    if not payload.job:
        raise HTTPException(422, "Le métier est requis")
    db.add(ProProfile(user_id=user.id, job=payload.job))
    user.role = "pro" if user.role == "client" else user.role
    db.flush()
    db.refresh(user)
    _apply_pro(db, user, payload)
    db.commit()
    cache.invalidate("pros")
    return pro_out(user)


@router.patch("/pros/me", response_model=ProOut)
def update_my_pro(payload: ProUpsert, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    _apply_pro(db, user, payload)
    db.commit()
    cache.invalidate("pros")
    return pro_out(user)


def _apply_pro(db: Session, user: User, payload: ProUpsert) -> None:
    data = payload.model_dump(exclude_unset=True)
    if "category" in data:
        name = data.pop("category")
        cat = db.scalars(select(Category).where(Category.name == name)).first() if name else None
        if name and not cat:
            raise HTTPException(422, f"Catégorie inconnue : {name}")
        user.pro.category_id = cat.id if cat else None
    for k, v in data.items():
        setattr(user.pro, k, v)


@router.get("/pros/me/kyc", response_model=list[KycDocOut])
def my_kyc(db: Session = Depends(get_db), user: User = Depends(require_pro)):
    return db.scalars(select(KycDocument).where(KycDocument.pro_id == user.id)
                      .order_by(KycDocument.created_at)).all()


@router.post("/pros/me/kyc", response_model=KycDocOut, status_code=201)
def submit_kyc(payload: KycDocIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    doc = KycDocument(pro_id=user.id, kind=payload.kind, file_url=payload.file_url)
    db.add(doc)
    user.pro.kyc_status = "pending"
    db.commit()
    return doc


@router.get("/pros/me/dashboard")
def my_dashboard(db: Session = Depends(get_db), user: User = Depends(require_pro)):
    """KPIs du jour + alertes (§8.2.1)."""
    now = utcnow()
    week = now - timedelta(days=7)
    count = lambda stmt: db.scalar(stmt) or 0  # noqa: E731
    revenue_7d = count(select(func.sum(Transaction.amount_xaf)).where(
        Transaction.user_id == user.id, Transaction.kind.in_(("order_payout", "ticket_payout", "tip_payout")),
        Transaction.created_at >= week))
    daily = []
    for i in range(6, -1, -1):
        start = (now - timedelta(days=i)).replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        daily.append({
            "date": start.date().isoformat(),
            "revenue_xaf": count(select(func.sum(Transaction.amount_xaf)).where(
                Transaction.user_id == user.id, Transaction.kind == "order_payout",
                Transaction.created_at >= start, Transaction.created_at < end)),
            "orders": count(select(func.count(Order.id)).where(
                Order.pro_id == user.id, Order.created_at >= start, Order.created_at < end)),
        })
    return {
        "followers": user.pro.followers_count,
        "new_followers_7d": count(select(func.count(Follow.id)).where(
            Follow.pro_id == user.id, Follow.created_at >= week)),
        "rating": round(user.pro.rating, 2),
        "revenue_7d_xaf": revenue_7d,
        "orders_in_progress": count(select(func.count(Order.id)).where(
            Order.pro_id == user.id, Order.status.in_(("pending", "in_progress", "delivered")))),
        "orders_total": count(select(func.count(Order.id)).where(Order.pro_id == user.id)),
        "alerts": {
            "pending_quotes": count(select(func.count(QuoteRequest.id)).where(
                QuoteRequest.pro_id == user.id, QuoteRequest.status == "pending")),
            "open_disputes": count(select(func.count(Order.id)).where(
                Order.pro_id == user.id, Order.status == "disputed")),
            "orders_to_confirm": count(select(func.count(Order.id)).where(
                Order.pro_id == user.id, Order.status == "pending")),
            "kyc_status": user.pro.kyc_status,
            "plan": user.pro.plan,
        },
        "daily": daily,
    }


@router.get("/pros/me/stats")
def my_stats(days: int = Query(30, ge=1, le=365), db: Session = Depends(get_db),
             user: User = Depends(require_pro)):
    """Statistiques détaillées (§8.2.6) : par publication, prestation et live."""
    since = utcnow() - timedelta(days=days)
    posts = db.scalars(select(Post).where(Post.author_id == user.id, Post.created_at >= since)
                       .order_by(Post.likes_count.desc()).limit(20)).all()
    per_service = db.execute(
        select(Order.title, func.count(Order.id), func.coalesce(func.sum(Order.amount_xaf), 0))
        .where(Order.pro_id == user.id, Order.created_at >= since)
        .group_by(Order.title).order_by(func.count(Order.id).desc())
    ).all()
    lives = db.scalars(select(Live).where(Live.pro_id == user.id, Live.created_at >= since)).all()
    by_kind = dict(db.execute(
        select(Transaction.kind, func.coalesce(func.sum(Transaction.amount_xaf), 0))
        .where(Transaction.user_id == user.id, Transaction.created_at >= since)
        .group_by(Transaction.kind)
    ).all())
    return {
        "period_days": days,
        "engagement": {
            "likes": sum(p.likes_count for p in posts),
            "comments": sum(p.comments_count for p in posts),
            "posts": len(posts),
        },
        "revenue": {
            "services_xaf": by_kind.get("order_payout", 0),
            "lives_xaf": by_kind.get("ticket_payout", 0),
            "tips_xaf": by_kind.get("tip_payout", 0),
            "commissions_xaf": -by_kind.get("commission", 0),
            "withdrawn_xaf": -by_kind.get("withdraw", 0),
        },
        "posts": [{"id": p.id, "text": p.text[:80], "likes": p.likes_count,
                   "comments": p.comments_count} for p in posts],
        "services": [{"title": t, "orders": n, "revenue_xaf": int(r)} for t, n, r in per_service],
        "lives": [{"id": lv.id, "title": lv.title, "peak_viewers": lv.peak_viewers,
                   "tips_xaf": lv.tips_xaf, "status": lv.status} for lv in lives],
    }


# ------------------------------------------------------------------ packs

@router.get("/plans", tags=["plans"])
def plans(db: Session = Depends(get_db)):
    return cache.cached("settings", "plans", 3600, lambda: get_setting(db, "plans"))


@router.post("/plans/subscribe", response_model=ProOut, tags=["plans"])
def subscribe(payload: SubscribeIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    plan = get_setting(db, "plans")[payload.plan]
    total = int(plan["price_xaf"]) * payload.months
    ledger.debit(db, user.id, total, "subscription",
                 f"Pack {plan['label']} — {payload.months} mois")
    now = utcnow()
    base = user.pro.plan_until if user.pro.plan_until and user.pro.plan_until > now else now
    user.pro.plan = payload.plan
    user.pro.plan_until = base + timedelta(days=30 * payload.months)
    db.commit()
    cache.invalidate("pros")
    return pro_out(user)
