import csv
import io

from fastapi import APIRouter, Depends, HTTPException, Request
from fastapi.responses import StreamingResponse
from sqlalchemy import select
from sqlalchemy.orm import Session

from app.core.config import settings
from app.core.deps import Page, current_user, require_pro
from app.db import get_db
from app.models import Transaction, User
from app.schemas import TopUpIn, TxOut, WalletOut, WithdrawIn, tx_out, wallet_out
from app.services import ledger, otp, payments
from app.services.notify import notify
from app.services.orders import confirm_topup

router = APIRouter(prefix="/wallet", tags=["wallet"])


@router.get("", response_model=WalletOut)
def get_wallet(db: Session = Depends(get_db), user: User = Depends(current_user)):
    w = ledger.wallet_of(db, user.id)
    db.commit()
    return wallet_out(w, ledger.monthly_volume(db, user.id), user.two_fa_enabled)


@router.get("/transactions", response_model=list[TxOut])
def transactions(kind: str | None = None, page: Page = Depends(), db: Session = Depends(get_db),
                 user: User = Depends(current_user)):
    stmt = select(Transaction).where(Transaction.user_id == user.id)
    if kind:
        stmt = stmt.where(Transaction.kind.in_(kind.split(",")))
    rows = db.scalars(stmt.order_by(Transaction.created_at.desc())
                      .limit(page.limit).offset(page.offset)).all()
    return [tx_out(t) for t in rows]


@router.get("/statement.csv")
def statement(db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Export du relevé (portefeuille et finances pro)."""
    rows = db.scalars(select(Transaction).where(Transaction.user_id == user.id)
                      .order_by(Transaction.created_at.desc())).all()
    buf = io.StringIO()
    w = csv.writer(buf, delimiter=";")
    w.writerow(["date", "reference", "type", "libelle", "montant_xaf", "statut", "moyen"])
    for t in rows:
        w.writerow([t.created_at.isoformat(), t.reference, t.kind, t.label, t.amount_xaf,
                    t.status, t.method or ""])
    buf.seek(0)
    return StreamingResponse(iter([buf.getvalue()]), media_type="text/csv",
                             headers={"Content-Disposition": "attachment; filename=releve-prolink.csv"})


@router.post("/topup", response_model=TxOut, status_code=201)
def topup(payload: TopUpIn, request: Request, db: Session = Depends(get_db),
          user: User = Depends(current_user)):
    ledger.require_2fa_if_needed(db, user, payload.amount_xaf)
    tx = ledger.record(db, user.id, "topup", payload.amount_xaf,
                       f"Rechargement {payload.method.upper()}", status="pending",
                       method=payload.method, phone=payload.phone, prefix="PAY")
    res = payments.init_payment(tx.reference, payload.amount_xaf, "Rechargement ProLink",
                                payload.phone, str(request.url_for("cinetpay_notify")))
    if res["status"] == "completed":
        confirm_topup(db, tx)
    elif res["status"] == "failed":
        tx.status = "failed"
    else:
        tx.meta = {"payment_url": res["payment_url"]}
    db.commit()
    return tx_out(tx)


@router.post("/cinetpay/notify", name="cinetpay_notify", include_in_schema=True)
async def cinetpay_notify(request: Request, db: Session = Depends(get_db)):
    """Webhook CinetPay : on revérifie toujours le statut auprès de l'API."""
    form = await request.form() if "form" in request.headers.get("content-type", "") else {}
    ref = form.get("cpm_trans_id") if form else (await request.json()).get("cpm_trans_id")
    tx = db.scalars(select(Transaction).where(Transaction.reference == ref)).first() if ref else None
    if not tx:
        raise HTTPException(404, "Transaction inconnue")
    status = payments.check_payment(tx.reference)
    if status == "completed":
        confirm_topup(db, tx)
    elif status == "failed":
        tx.status = "failed"
    db.commit()
    return {"reference": tx.reference, "status": tx.status}


@router.post("/withdraw", response_model=TxOut, status_code=201)
def withdraw(payload: WithdrawIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    """Retrait vers Mobile Money (pros uniquement), confirmé par code SMS."""
    if payload.amount_xaf < settings.withdraw_min_xaf:
        raise HTTPException(400, f"Retrait minimum : {settings.withdraw_min_xaf} XAF")
    w = ledger.wallet_of(db, user.id, lock=True)
    if w.balance_xaf - payload.amount_xaf < settings.wallet_min_balance_xaf:
        raise HTTPException(402, f"Le solde doit rester ≥ {settings.wallet_min_balance_xaf} XAF "
                                 f"(retirable : {max(0, w.balance_xaf - settings.wallet_min_balance_xaf)} XAF)")
    ledger.require_2fa_if_needed(db, user, payload.amount_xaf)
    otp.consume(db, user.id, "withdraw", payload.otp)
    fees = round(payload.amount_xaf * 0.01)
    tx = ledger.debit(db, user.id, payload.amount_xaf, "withdraw",
                      f"Retrait {payload.operator.upper()} → {payload.phone}",
                      method=payload.operator, phone=payload.phone, prefix="WD",
                      meta={"operator_fees_xaf": fees, "net_xaf": payload.amount_xaf - fees})
    tx.status = payments.payout(tx.reference, payload.amount_xaf - fees, payload.phone, payload.operator)
    notify(db, user.id, "payment", "Retrait en cours" if tx.status == "pending" else "Retrait effectué",
           f"{payload.amount_xaf - fees} XAF vers {payload.phone}", {"tx": tx.reference})
    db.commit()
    return tx_out(tx)
