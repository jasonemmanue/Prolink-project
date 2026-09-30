"""Mobile Money via CinetPay (MVP). Sans clés configurées : mode sandbox
où chaque paiement est confirmé immédiatement (dev / démo / tests)."""
import logging

import httpx

from app.core.config import settings

log = logging.getLogger("prolink.payments")

CINETPAY_INIT = "https://api-checkout.cinetpay.com/v2/payment"
CINETPAY_CHECK = "https://api-checkout.cinetpay.com/v2/payment/check"


def init_payment(reference: str, amount: int, description: str, phone: str | None,
                 notify_url: str) -> dict:
    """Retourne {"status": "completed"|"pending", "payment_url": ...}."""
    if settings.payments_sandbox:
        return {"status": "completed", "payment_url": None, "provider": "sandbox"}
    payload = {
        "apikey": settings.cinetpay_api_key,
        "site_id": settings.cinetpay_site_id,
        "transaction_id": reference,
        "amount": amount,
        "currency": "XAF",
        "description": description,
        "notify_url": notify_url,
        "return_url": notify_url,
        "channels": "MOBILE_MONEY",
        "customer_phone_number": phone or "",
    }
    try:
        r = httpx.post(CINETPAY_INIT, json=payload, timeout=15)
        data = r.json()
        url = (data.get("data") or {}).get("payment_url")
        return {"status": "pending", "payment_url": url, "provider": "cinetpay"}
    except Exception as e:  # réseau / fournisseur
        log.warning("CinetPay init échoué : %s", e)
        return {"status": "failed", "payment_url": None, "provider": "cinetpay"}


def check_payment(reference: str) -> str:
    """Statut CinetPay : completed | pending | failed."""
    if settings.payments_sandbox:
        return "completed"
    try:
        r = httpx.post(CINETPAY_CHECK, json={
            "apikey": settings.cinetpay_api_key,
            "site_id": settings.cinetpay_site_id,
            "transaction_id": reference,
        }, timeout=15)
        status = ((r.json().get("data") or {}).get("status") or "").upper()
    except Exception:
        return "pending"
    return {"ACCEPTED": "completed", "REFUSED": "failed"}.get(status, "pending")


def payout(reference: str, amount: int, phone: str, operator: str) -> str:
    """Transfert sortant vers Mobile Money (retrait)."""
    if settings.payments_sandbox:
        return "completed"
    # API transfert CinetPay (auth + contact + transfer) à brancher en Phase 2.
    log.info("Payout %s %s XAF → %s (%s) mis en file", reference, amount, phone, operator)
    return "pending"
