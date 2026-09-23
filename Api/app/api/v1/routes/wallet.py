from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/wallet", tags=["wallet"])


class Wallet(BaseModel):
    balance_xaf: int
    escrow_xaf: int


@router.get("", response_model=Wallet)
def get_wallet():
    return Wallet(balance_xaf=45000, escrow_xaf=250000)


@router.post("/topup")
def topup(operator: str, phone: str, amount_xaf: int):
    return {"tx": "CINETPAY-TX-101", "operator": operator, "status": "pending"}


@router.post("/withdraw")
def withdraw(operator: str, phone: str, amount_xaf: int):
    if amount_xaf < 5000:
        return {"error": "min 5000 XAF"}
    return {"tx": "WD-TX-101", "operator": operator, "amount": amount_xaf, "eta_hours": 48}
