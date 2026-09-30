"""Back-office. Chaque action d'écriture est tracée dans `audit_logs`."""
import csv
import io
from datetime import timedelta
from typing import Literal

from fastapi import APIRouter, Depends, HTTPException, Query, Request
from fastapi.responses import StreamingResponse
from pydantic import BaseModel, Field
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.deps import Page, require_admin
from app.db import get_db, utcnow
from app.models import (
    AuditLog, BannedKeyword, Campaign, Category, Dispute, KycDocument, Live, Order, Post,
    PostComment, ProProfile, Report, Review, Transaction, User,
)
from app.schemas import (
    CampaignOut, CategoryOut, DisputeOut, KycDocOut, LiveOut, MeOut, OrderOut, ReportOut,
    campaign_out, live_out, me_out, order_out,
)
from app.services import cache, ledger
from app.services import orders as order_svc
from app.services.notify import notify, notify_many
from app.services.platform import audit, commission, get_setting, set_setting

router = APIRouter(prefix="/admin", tags=["admin"])


def _ip(request: Request) -> str | None:
    return request.client.host if request.client else None


# ------------------------------------------------------------------ dashboard

@router.get("/dashboard")
def dashboard(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return cache.cached("admin", "dashboard", 30, lambda: _dashboard(db))


def _dashboard(db: Session) -> dict:
    now = utcnow()
    month = now - timedelta(days=30)
    n = lambda stmt: db.scalar(stmt) or 0  # noqa: E731
    return {
        "users_total": n(select(func.count(User.id))),
        "clients": n(select(func.count(User.id)).where(User.role == "client")),
        "pros": n(select(func.count(ProProfile.user_id))),
        "pros_verified": n(select(func.count(ProProfile.user_id)).where(ProProfile.verified_level > 0)),
        "kyc_pending": n(select(func.count(KycDocument.id)).where(KycDocument.status == "pending")),
        "new_users_30d": n(select(func.count(User.id)).where(User.created_at >= month)),
        "orders_30d": n(select(func.count(Order.id)).where(Order.created_at >= month)),
        "orders_in_escrow": n(select(func.count(Order.id)).where(
            Order.status.in_(("pending", "in_progress", "delivered", "disputed")))),
        "escrow_xaf": n(select(func.sum(Order.amount_xaf)).where(
            Order.status.in_(("pending", "in_progress", "delivered", "disputed")))),
        "gmv_30d_xaf": n(select(func.sum(Order.amount_xaf)).where(
            Order.created_at >= month, Order.status != "cancelled")),
        "revenue_30d_xaf": -n(select(func.sum(Transaction.amount_xaf)).where(
            Transaction.kind == "commission", Transaction.created_at >= month)),
        "sponsoring_30d_xaf": -n(select(func.sum(Transaction.amount_xaf)).where(
            Transaction.kind == "sponsorship", Transaction.created_at >= month)),
        "lives_live_now": n(select(func.count(Live.id)).where(Live.status == "live")),
        "open_disputes": n(select(func.count(Dispute.id)).where(Dispute.status == "open")),
        "open_reports": n(select(func.count(Report.id)).where(Report.status == "open")),
        "campaigns_to_review": n(select(func.count(Campaign.id)).where(Campaign.status == "pending_review")),
    }


@router.get("/analytics")
def analytics(days: int = Query(30, ge=7, le=365), db: Session = Depends(get_db),
              admin: User = Depends(require_admin)):
    since = utcnow() - timedelta(days=days)
    day = func.date_trunc("day", User.created_at)
    signups = db.execute(select(day, func.count(User.id)).where(User.created_at >= since)
                         .group_by(day).order_by(day)).all()
    oday = func.date_trunc("day", Order.created_at)
    orders = db.execute(select(oday, func.count(Order.id), func.coalesce(func.sum(Order.amount_xaf), 0))
                        .where(Order.created_at >= since).group_by(oday).order_by(oday)).all()
    buyers = db.scalar(select(func.count(func.distinct(Order.client_id))).where(Order.created_at >= since)) or 0
    clients = db.scalar(select(func.count(User.id)).where(User.role == "client")) or 1
    top = db.execute(select(User.name, func.count(Order.id), func.sum(Order.amount_xaf))
                     .join(Order, Order.pro_id == User.id).where(Order.created_at >= since)
                     .group_by(User.name).order_by(func.sum(Order.amount_xaf).desc()).limit(10)).all()
    return {
        "signups": [{"date": d.date().isoformat(), "count": c} for d, c in signups],
        "orders": [{"date": d.date().isoformat(), "count": c, "gmv_xaf": int(v)} for d, c, v in orders],
        "buyer_conversion_pct": round(100 * buyers / clients, 1),
        "top_pros": [{"name": nm, "orders": c, "gmv_xaf": int(v or 0)} for nm, c, v in top],
    }


# ---------------------------------------------------------------- utilisateurs

@router.get("/users", response_model=list[MeOut])
def users(role: str | None = None, q: str | None = None, active: bool | None = None,
          page: Page = Depends(), db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    stmt = select(User)
    if role:
        stmt = stmt.where(User.role == role)
    if active is not None:
        stmt = stmt.where(User.is_active.is_(active))
    if q:
        like = f"%{q.lower()}%"
        stmt = stmt.where(or_(func.lower(User.name).like(like), func.lower(User.email).like(like),
                              User.phone.like(like)))
    rows = db.scalars(stmt.order_by(User.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [me_out(u) for u in rows]


class ReasonIn(BaseModel):
    reason: str = Field(min_length=3, max_length=300)


@router.post("/users/{uid}/suspend", response_model=MeOut)
def suspend(uid: str, payload: ReasonIn, request: Request, db: Session = Depends(get_db),
            admin: User = Depends(require_admin)):
    u = db.get(User, uid)
    if not u or u.role == "admin":
        raise HTTPException(404, "Utilisateur introuvable")
    u.is_active = False
    audit(db, admin.id, "user.suspend", "user", uid, {"reason": payload.reason}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return me_out(u)


@router.post("/users/{uid}/reactivate", response_model=MeOut)
def reactivate(uid: str, request: Request, db: Session = Depends(get_db),
               admin: User = Depends(require_admin)):
    u = db.get(User, uid)
    if not u:
        raise HTTPException(404, "Utilisateur introuvable")
    u.is_active = True
    audit(db, admin.id, "user.reactivate", "user", uid, {}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return me_out(u)


# ------------------------------------------------------------------------ KYC

@router.get("/kyc", response_model=list[KycDocOut])
def kyc_queue(status: str = "pending", db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return db.scalars(select(KycDocument).where(KycDocument.status == status)
                      .order_by(KycDocument.created_at)).all()


class KycDecisionIn(BaseModel):
    decision: Literal["approved", "rejected"]
    note: str | None = None


@router.post("/kyc/{doc_id}", response_model=KycDocOut)
def kyc_decide(doc_id: str, payload: KycDecisionIn, request: Request, db: Session = Depends(get_db),
               admin: User = Depends(require_admin)):
    doc = db.get(KycDocument, doc_id)
    if not doc:
        raise HTTPException(404, "Document introuvable")
    doc.status, doc.note = payload.decision, payload.note
    doc.reviewed_by, doc.reviewed_at = admin.id, utcnow()
    pro = db.get(ProProfile, doc.pro_id)
    docs = db.scalars(select(KycDocument).where(KycDocument.pro_id == doc.pro_id)).all()
    approved = {d.kind for d in docs if d.status == "approved"}
    if payload.decision == "rejected":
        pro.kyc_status = "rejected"
    elif {"id_card", "selfie"} <= approved:
        pro.kyc_status = "approved"
        # Niveaux : bleu (identité) → or (+ justificatif pro) → violet (+ diplômes).
        level = 1
        if {"registry", "address"} & approved:
            level = 2
        if "diploma" in approved and level == 2:
            level = 3
        pro.verified_level = max(pro.verified_level, level)
    notify(db, doc.pro_id, "system", "Vérification KYC",
           f"Document « {doc.kind} » {'validé' if payload.decision == 'approved' else 'refusé'}."
           + (f" {payload.note}" if payload.note else ""), {"doc_id": doc.id})
    audit(db, admin.id, f"kyc.{payload.decision}", "kyc", doc.id,
          {"pro_id": doc.pro_id, "kind": doc.kind, "note": payload.note}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return doc


class VerificationIn(BaseModel):
    level: int = Field(ge=0, le=3)


@router.post("/pros/{pid}/verification")
def set_verification(pid: str, payload: VerificationIn, request: Request, db: Session = Depends(get_db),
                     admin: User = Depends(require_admin)):
    pro = db.get(ProProfile, pid)
    if not pro:
        raise HTTPException(404, "Pro introuvable")
    pro.verified_level = payload.level
    audit(db, admin.id, "pro.verification", "pro", pid, {"level": payload.level}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return {"pro_id": pid, "verified_level": pro.verified_level}


# ----------------------------------------------------------------- modération

@router.get("/reports", response_model=list[ReportOut])
def reports(status: str = "open", page: Page = Depends(), db: Session = Depends(get_db),
            admin: User = Depends(require_admin)):
    return db.scalars(select(Report).where(Report.status == status).order_by(Report.created_at)
                      .limit(page.limit).offset(page.offset)).all()


class ResolveReportIn(BaseModel):
    action: Literal["keep", "hide", "remove", "warn", "suspend"]
    note: str | None = None


@router.post("/reports/{rid}/resolve", response_model=ReportOut)
def resolve_report(rid: str, payload: ResolveReportIn, request: Request, db: Session = Depends(get_db),
                   admin: User = Depends(require_admin)):
    r = db.get(Report, rid)
    if not r:
        raise HTTPException(404, "Signalement introuvable")
    target = {"post": Post, "comment": PostComment, "review": Review}.get(r.target_type)
    obj = db.get(target, r.target_id) if target else None
    owner_id = None
    if obj is not None:
        owner_id = getattr(obj, "author_id", None)
        if payload.action in ("hide", "remove"):
            obj.hidden = True
    elif r.target_type in ("pro", "user"):
        owner_id = r.target_id
    elif r.target_type == "live":
        lv = db.get(Live, r.target_id)
        owner_id = lv.pro_id if lv else None
        if lv and payload.action in ("hide", "remove"):
            lv.status = "cut"
    if payload.action == "suspend" and owner_id:
        u = db.get(User, owner_id)
        if u and u.role != "admin":
            u.is_active = False
    if payload.action in ("warn", "hide", "remove", "suspend") and owner_id:
        notify(db, owner_id, "system", "Avertissement de modération",
               payload.note or f"Votre contenu a été signalé ({r.reason}).", {"report_id": r.id})
    r.status = {"keep": "kept", "hide": "hidden", "remove": "removed", "warn": "warned",
                "suspend": "removed"}[payload.action]
    r.resolved_by = admin.id
    audit(db, admin.id, f"report.{payload.action}", r.target_type, r.target_id,
          {"report_id": r.id, "note": payload.note}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return r


@router.get("/keywords")
def keywords(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return [{"id": k.id, "word": k.word} for k in db.scalars(select(BannedKeyword).order_by(BannedKeyword.word))]


class KeywordIn(BaseModel):
    word: str = Field(min_length=2, max_length=80)


@router.post("/keywords", status_code=201)
def add_keyword(payload: KeywordIn, request: Request, db: Session = Depends(get_db),
                admin: User = Depends(require_admin)):
    word = payload.word.strip().lower()
    if db.scalars(select(BannedKeyword).where(BannedKeyword.word == word)).first():
        raise HTTPException(409, "Mot-clé déjà banni")
    k = BannedKeyword(word=word)
    db.add(k)
    audit(db, admin.id, "keyword.add", "keyword", word, {}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return {"id": k.id, "word": k.word}


@router.delete("/keywords/{kid}", status_code=204)
def delete_keyword(kid: int, request: Request, db: Session = Depends(get_db),
                   admin: User = Depends(require_admin)):
    k = db.get(BannedKeyword, kid)
    if k:
        audit(db, admin.id, "keyword.remove", "keyword", k.word, {}, _ip(request))
        db.delete(k)
        db.commit()
        cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")


# ---------------------------------------------------------------- catégories

@router.get("/categories", response_model=list[CategoryOut])
def all_categories(db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return db.scalars(select(Category).order_by(Category.position)).all()


class CategoryIn(BaseModel):
    name: str = Field(min_length=2, max_length=80)
    parent_id: int | None = None
    position: int = 0
    active: bool = True


@router.post("/categories", response_model=CategoryOut, status_code=201)
def create_category(payload: CategoryIn, request: Request, db: Session = Depends(get_db),
                    admin: User = Depends(require_admin)):
    if db.scalars(select(Category).where(Category.name == payload.name)).first():
        raise HTTPException(409, "Catégorie existante")
    c = Category(**payload.model_dump())
    db.add(c)
    db.flush()
    audit(db, admin.id, "category.create", "category", str(c.id), payload.model_dump(), _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return c


@router.patch("/categories/{cid}", response_model=CategoryOut)
def update_category(cid: int, payload: CategoryIn, request: Request, db: Session = Depends(get_db),
                    admin: User = Depends(require_admin)):
    c = db.get(Category, cid)
    if not c:
        raise HTTPException(404, "Catégorie introuvable")
    for k, v in payload.model_dump().items():
        setattr(c, k, v)
    audit(db, admin.id, "category.update", "category", str(cid), payload.model_dump(), _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return c


class MergeIn(BaseModel):
    source_id: int
    target_id: int


@router.post("/categories/merge", response_model=CategoryOut)
def merge_categories(payload: MergeIn, request: Request, db: Session = Depends(get_db),
                     admin: User = Depends(require_admin)):
    src, dst = db.get(Category, payload.source_id), db.get(Category, payload.target_id)
    if not src or not dst or src.id == dst.id:
        raise HTTPException(400, "Catégories invalides")
    for p in db.scalars(select(ProProfile).where(ProProfile.category_id == src.id)):
        p.category_id = dst.id
    src.active = False
    audit(db, admin.id, "category.merge", "category", str(dst.id), payload.model_dump(), _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return dst


# ---------------------------------------------------------- tarifs / paramètres

@router.get("/settings/{key}")
def read_setting(key: str, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return get_setting(db, key)


@router.put("/settings/{key}")
def write_setting(key: Literal["commissions", "plans", "sponsorship", "legal"], value: dict,
                  request: Request, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    if key == "commissions":
        for k, v in value.items():
            if not 0 <= float(v) <= 50:
                raise HTTPException(422, f"{k} doit être entre 0 et 50 %")
    merged = set_setting(db, key, value)
    audit(db, admin.id, f"settings.{key}", "settings", key, value, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return merged


# -------------------------------------------------------- litiges & séquestre

@router.get("/disputes", response_model=list[DisputeOut])
def disputes(status: str = "open", db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return db.scalars(select(Dispute).where(Dispute.status == status).order_by(Dispute.created_at)).all()


class ResolveDisputeIn(BaseModel):
    resolution: Literal["refund", "release", "split"]
    refund_xaf: int = Field(0, ge=0, description="Montant remboursé au client si split")
    note: str = Field(min_length=3, max_length=1000)


@router.post("/disputes/{did}/resolve", response_model=DisputeOut)
def resolve_dispute(did: str, payload: ResolveDisputeIn, request: Request, db: Session = Depends(get_db),
                    admin: User = Depends(require_admin)):
    d = db.get(Dispute, did)
    if not d or d.status != "open":
        raise HTTPException(404, "Litige ouvert introuvable")
    o = d.order
    label = f"{o.title} ({o.code})"
    if payload.resolution == "release":
        order_svc.complete(db, o)
        d.refund_xaf = 0
    elif payload.resolution == "refund":
        order_svc.refund(db, o, "litige arbitré en faveur du client")
        d.refund_xaf = o.amount_xaf
    else:
        if not 0 < payload.refund_xaf < o.amount_xaf:
            raise HTTPException(422, "Montant de remboursement partiel invalide")
        rest = o.amount_xaf - payload.refund_xaf
        ledger.refund_order_funds(db, o.client_id, o.pro_id, o.amount_xaf, o.net_xaf, o.id, label,
                                  refund=payload.refund_xaf, commission=commission(db, "service", rest))
        o.status = "completed"
        o.completed_at = utcnow()
        d.refund_xaf = payload.refund_xaf
        for uid in (o.client_id, o.pro_id):
            notify(db, uid, "order", f"Litige {o.code} tranché",
                   f"Remboursement partiel : {payload.refund_xaf} XAF au client.", {"order_id": o.id})
    d.status, d.resolution = "resolved", payload.resolution
    d.resolved_by, d.resolved_at = admin.id, utcnow()
    d.events = [*d.events, {"at": utcnow().isoformat(), "by": admin.id, "text": f"Décision : {payload.note}"}]
    audit(db, admin.id, f"dispute.{payload.resolution}", "order", o.id,
          {"dispute_id": d.id, "refund_xaf": d.refund_xaf, "note": payload.note}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return d


@router.get("/orders", response_model=list[OrderOut])
def all_orders(status: str | None = None, page: Page = Depends(), db: Session = Depends(get_db),
               admin: User = Depends(require_admin)):
    stmt = select(Order)
    if status:
        stmt = stmt.where(Order.status.in_(status.split(",")))
    rows = db.scalars(stmt.order_by(Order.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [order_out(o) for o in rows]


@router.post("/orders/{oid}/release", response_model=OrderOut)
def manual_release(oid: str, payload: ReasonIn, request: Request, db: Session = Depends(get_db),
                   admin: User = Depends(require_admin)):
    o = db.get(Order, oid)
    if not o or o.status not in ("in_progress", "delivered"):
        raise HTTPException(409, "Libération impossible pour cette commande")
    order_svc.complete(db, o)
    audit(db, admin.id, "order.release_manual", "order", o.id, {"reason": payload.reason}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return order_out(o)


@router.post("/orders/{oid}/refund", response_model=OrderOut)
def manual_refund(oid: str, payload: ReasonIn, request: Request, db: Session = Depends(get_db),
                  admin: User = Depends(require_admin)):
    o = db.get(Order, oid)
    if not o or o.status not in ("pending", "in_progress", "delivered"):
        raise HTTPException(409, "Remboursement impossible pour cette commande")
    order_svc.refund(db, o, payload.reason)
    audit(db, admin.id, "order.refund_manual", "order", o.id, {"reason": payload.reason}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return order_out(o)


@router.post("/orders/auto-release")
def run_auto_release(request: Request, db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    n = order_svc.release_due_orders(db)
    audit(db, admin.id, "order.auto_release_run", None, None, {"released": n}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return {"released": n}


# --------------------------------------------------------------------- lives

@router.get("/lives", response_model=list[LiveOut])
def lives(status: str = "live", db: Session = Depends(get_db), admin: User = Depends(require_admin)):
    return [live_out(lv, True) for lv in db.scalars(select(Live).where(Live.status == status))]


@router.post("/lives/{lid}/cut", response_model=LiveOut)
def cut_live(lid: str, payload: ReasonIn, request: Request, db: Session = Depends(get_db),
             admin: User = Depends(require_admin)):
    """Coupure d'urgence d'un live."""
    lv = db.get(Live, lid)
    if not lv or lv.status != "live":
        raise HTTPException(409, "Live non en cours")
    lv.status, lv.ended_at, lv.viewers = "cut", utcnow(), 0
    notify(db, lv.pro_id, "system", "Live interrompu par la modération", payload.reason, {"live_id": lid})
    audit(db, admin.id, "live.cut", "live", lid, {"reason": payload.reason}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return live_out(lv, True)


# ------------------------------------------------------------------ publicité

@router.get("/campaigns", response_model=list[CampaignOut])
def campaigns(status: str = "pending_review", db: Session = Depends(get_db),
              admin: User = Depends(require_admin)):
    return [campaign_out(c) for c in db.scalars(select(Campaign).where(Campaign.status == status))]


class CampaignReviewIn(BaseModel):
    approve: bool
    note: str | None = None


@router.post("/campaigns/{cid}/review", response_model=CampaignOut)
def review_campaign(cid: str, payload: CampaignReviewIn, request: Request, db: Session = Depends(get_db),
                    admin: User = Depends(require_admin)):
    c = db.get(Campaign, cid)
    if not c or c.status != "pending_review":
        raise HTTPException(404, "Campagne à valider introuvable")
    if payload.approve:
        c.status, c.starts_at = "active", utcnow()
        if c.target_type == "post" and c.target_id and (p := db.get(Post, c.target_id)):
            p.sponsored = True
    else:
        c.status = "rejected"
        ledger.credit(db, c.owner_id, c.total_xaf, "refund", "Campagne refusée — budget restitué",
                      related_id=c.id)
    notify(db, c.owner_id, "system", "Campagne " + ("validée" if payload.approve else "refusée"),
           payload.note or "", {"campaign_id": c.id})
    audit(db, admin.id, "campaign.approve" if payload.approve else "campaign.reject", "campaign", c.id,
          {"note": payload.note}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return campaign_out(c)


# -------------------------------------------------------------- notifications

class BroadcastIn(BaseModel):
    title: str = Field(min_length=3, max_length=200)
    body: str = Field(min_length=1, max_length=1000)
    segment: str = Field("all", description="all | clients | pros | city:<Ville>")


@router.post("/notifications/broadcast")
def broadcast(payload: BroadcastIn, request: Request, db: Session = Depends(get_db),
              admin: User = Depends(require_admin)):
    stmt = select(User.id).where(User.is_active.is_(True))
    if payload.segment == "clients":
        stmt = stmt.where(User.role == "client")
    elif payload.segment == "pros":
        stmt = stmt.where(User.role == "pro")
    elif payload.segment.startswith("city:"):
        stmt = stmt.where(func.lower(User.city) == payload.segment[5:].lower())
    ids = list(db.scalars(stmt))
    sent = notify_many(db, ids, "system", payload.title, payload.body, {"broadcast": True})
    audit(db, admin.id, "notification.broadcast", "segment", payload.segment,
          {"title": payload.title, "recipients": sent}, _ip(request))
    db.commit()
    cache.invalidate("pros", "feed", "lives", "services", "categories", "settings", "admin")
    return {"recipients": sent}


# ---------------------------------------------------------------- finances

@router.get("/finances/summary")
def finances(days: int = Query(30, ge=1, le=365), db: Session = Depends(get_db),
             admin: User = Depends(require_admin)):
    since = utcnow() - timedelta(days=days)
    by_kind = dict(db.execute(select(Transaction.kind, func.coalesce(func.sum(Transaction.amount_xaf), 0))
                              .where(Transaction.created_at >= since, Transaction.status == "completed")
                              .group_by(Transaction.kind)).all())
    return {
        "period_days": days,
        "topups_xaf": by_kind.get("topup", 0),
        "withdrawals_xaf": -by_kind.get("withdraw", 0),
        "commissions_xaf": -by_kind.get("commission", 0),
        "sponsorship_xaf": -by_kind.get("sponsorship", 0),
        "subscriptions_xaf": -by_kind.get("subscription", 0),
        "refunds_xaf": by_kind.get("refund", 0),
        "pending_payouts": db.scalar(select(func.count(Transaction.id)).where(
            Transaction.kind == "withdraw", Transaction.status == "pending")) or 0,
        "by_kind": by_kind,
    }


@router.get("/finances/export.csv")
def export_finances(days: int = Query(30, ge=1, le=365), db: Session = Depends(get_db),
                    admin: User = Depends(require_admin)):
    """Export comptable (réconciliation Mobile Money)."""
    since = utcnow() - timedelta(days=days)
    rows = db.execute(select(Transaction, User.name).join(User, User.id == Transaction.user_id)
                      .where(Transaction.created_at >= since).order_by(Transaction.created_at)).all()
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["date", "reference", "utilisateur", "type", "libelle", "montant_xaf", "statut", "moyen", "telephone"])
    for t, name in rows:
        w.writerow([t.created_at.isoformat(), t.reference, name, t.kind, t.label, t.amount_xaf,
                    t.status, t.method or "", t.phone or ""])
    buf.seek(0)
    return StreamingResponse(iter([buf.getvalue()]), media_type="text/csv",
                             headers={"Content-Disposition": "attachment; filename=finances-prolink.csv"})


# ------------------------------------------------------------------ audit

@router.get("/audit")
def audit_log(action: str | None = None, page: Page = Depends(), db: Session = Depends(get_db),
              admin: User = Depends(require_admin)):
    stmt = select(AuditLog, User.name).join(User, User.id == AuditLog.actor_id)
    if action:
        stmt = stmt.where(AuditLog.action.like(f"{action}%"))
    rows = db.execute(stmt.order_by(AuditLog.created_at.desc()).limit(page.limit).offset(page.offset)).all()
    return [{"id": a.id, "at": a.created_at, "actor": name, "actor_id": a.actor_id, "action": a.action,
             "target_type": a.target_type, "target_id": a.target_id, "payload": a.payload, "ip": a.ip}
            for a, name in rows]
