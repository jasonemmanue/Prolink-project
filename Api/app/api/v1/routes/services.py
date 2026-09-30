from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import func, or_, select
from sqlalchemy.orm import Session

from app.core.deps import Page, current_user, require_pro
from app.db import get_db
from app.models import QuoteRequest, Service, User
from app.schemas import (
    QuoteIn, QuoteOut, QuoteReplyIn, ReorderIn, ServiceIn, ServiceOut, ServiceUpdate, quote_out,
    service_out,
)
from app.services.notify import notify
from app.services.platform import get_setting

router = APIRouter(tags=["services"])


def _own(db: Session, sid: str, user: User) -> Service:
    s = db.get(Service, sid)
    if not s:
        raise HTTPException(404, "Prestation introuvable")
    if s.pro_id != user.id and user.role != "admin":
        raise HTTPException(403, "Cette prestation ne vous appartient pas")
    return s


@router.get("/services", response_model=list[ServiceOut])
def search_services(
    q: str | None = None,
    category: str | None = None,
    pro_id: str | None = None,
    max_price: int | None = Query(None, ge=0),
    pricing_type: str | None = None,
    page: Page = Depends(),
    db: Session = Depends(get_db),
):
    stmt = select(Service).where(Service.status == "active")
    if q:
        like = f"%{q.lower()}%"
        stmt = stmt.where(or_(func.lower(Service.title).like(like),
                              func.lower(Service.description).like(like)))
    if category:
        stmt = stmt.where(Service.category == category)
    if pro_id:
        stmt = stmt.where(Service.pro_id == pro_id)
    if max_price is not None:
        stmt = stmt.where(Service.price_xaf <= max_price)
    if pricing_type:
        stmt = stmt.where(Service.pricing_type == pricing_type)
    rows = db.scalars(stmt.order_by(Service.pro_id, Service.position)
                      .limit(page.limit).offset(page.offset)).all()
    return [service_out(s) for s in rows]


@router.get("/services/{sid}", response_model=ServiceOut)
def get_service(sid: str, db: Session = Depends(get_db)):
    s = db.get(Service, sid)
    if not s:
        raise HTTPException(404, "Prestation introuvable")
    return service_out(s)


@router.post("/services", response_model=ServiceOut, status_code=201)
def create_service(payload: ServiceIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    limit = get_setting(db, "plans")[user.pro.plan].get("max_services")
    if limit is not None:
        n = db.scalar(select(func.count(Service.id)).where(Service.pro_id == user.id,
                                                           Service.status != "draft"))
        if payload.status != "draft" and n >= limit:
            raise HTTPException(402, f"Le pack {user.pro.plan} est limité à {limit} prestations actives")
    pos = db.scalar(select(func.coalesce(func.max(Service.position), -1)).where(Service.pro_id == user.id)) + 1
    s = Service(pro_id=user.id, position=pos, **payload.model_dump())
    db.add(s)
    db.commit()
    db.refresh(s)
    return service_out(s)


@router.patch("/services/{sid}", response_model=ServiceOut)
def update_service(sid: str, payload: ServiceUpdate, db: Session = Depends(get_db),
                   user: User = Depends(require_pro)):
    s = _own(db, sid, user)
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(s, k, v)
    db.commit()
    return service_out(s)


@router.delete("/services/{sid}", status_code=204)
def delete_service(sid: str, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    s = _own(db, sid, user)
    db.delete(s)
    db.commit()


@router.post("/services/reorder", response_model=list[ServiceOut])
def reorder(payload: ReorderIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    """Ordre d'affichage du catalogue (glisser-déposer)."""
    for i, sid in enumerate(payload.ids):
        _own(db, sid, user).position = i
    db.commit()
    rows = db.scalars(select(Service).where(Service.pro_id == user.id).order_by(Service.position)).all()
    return [service_out(s) for s in rows]


# ---------------------------------------------------------------------- devis

@router.post("/quotes", response_model=QuoteOut, status_code=201, tags=["quotes"])
def request_quote(payload: QuoteIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    pro = db.get(User, payload.pro_id)
    if not pro or not pro.pro:
        raise HTTPException(404, "Professionnel introuvable")
    if pro.id == user.id:
        raise HTTPException(400, "Impossible de vous demander un devis")
    q = QuoteRequest(client_id=user.id, **payload.model_dump())
    db.add(q)
    db.flush()
    notify(db, pro.id, "order", "Nouvelle demande de devis", f"{user.name} : {payload.description[:100]}",
           {"quote_id": q.id})
    db.commit()
    db.refresh(q)
    return quote_out(q)


@router.get("/quotes", response_model=list[QuoteOut], tags=["quotes"])
def my_quotes(status: str | None = None, db: Session = Depends(get_db),
              user: User = Depends(current_user)):
    stmt = select(QuoteRequest).where(or_(QuoteRequest.client_id == user.id,
                                          QuoteRequest.pro_id == user.id))
    if status:
        stmt = stmt.where(QuoteRequest.status == status)
    return [quote_out(q) for q in db.scalars(stmt.order_by(QuoteRequest.created_at.desc()))]


def _quote(db: Session, qid: str, user: User) -> QuoteRequest:
    q = db.get(QuoteRequest, qid)
    if not q or user.id not in (q.client_id, q.pro_id):
        raise HTTPException(404, "Devis introuvable")
    return q


@router.get("/quotes/{qid}", response_model=QuoteOut, tags=["quotes"])
def get_quote(qid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    return quote_out(_quote(db, qid, user))


@router.post("/quotes/{qid}/reply", response_model=QuoteOut, tags=["quotes"])
def reply_quote(qid: str, payload: QuoteReplyIn, db: Session = Depends(get_db),
                user: User = Depends(require_pro)):
    q = _quote(db, qid, user)
    if q.pro_id != user.id:
        raise HTTPException(403, "Seul le pro sollicité peut répondre")
    if q.status not in ("pending", "quoted"):
        raise HTTPException(409, "Ce devis n'est plus modifiable")
    q.lines = [line.model_dump() for line in payload.lines]
    q.total_xaf = sum(line.amount_xaf for line in payload.lines)
    q.delay = payload.delay
    q.reply_message = payload.message
    q.status = "quoted"
    notify(db, q.client_id, "order", "Devis reçu", f"{user.name} vous propose {q.total_xaf} XAF.",
           {"quote_id": q.id})
    db.commit()
    return quote_out(q)


@router.post("/quotes/{qid}/decline", response_model=QuoteOut, tags=["quotes"])
def decline_quote(qid: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    q = _quote(db, qid, user)
    if q.status in ("accepted", "declined"):
        raise HTTPException(409, "Devis déjà clôturé")
    q.status = "declined"
    other = q.pro_id if user.id == q.client_id else q.client_id
    notify(db, other, "order", "Devis refusé", f"La demande de devis a été refusée par {user.name}.",
           {"quote_id": q.id})
    db.commit()
    return quote_out(q)
