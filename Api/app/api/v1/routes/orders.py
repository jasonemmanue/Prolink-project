from datetime import datetime
from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/orders", tags=["orders"])


class Order(BaseModel):
    id: str
    service_id: str
    client_id: str
    pro_id: str
    amount_xaf: int
    status: str  # initiated | confirmed | delivered | validated | disputed | refunded | released
    escrow: bool
    created_at: datetime


_MOCK: list[Order] = []


@router.post("", response_model=Order)
def create_order(service_id: str, client_id: str, pro_id: str, amount_xaf: int):
    o = Order(
        id=f"o{len(_MOCK) + 1}",
        service_id=service_id,
        client_id=client_id,
        pro_id=pro_id,
        amount_xaf=amount_xaf,
        status="initiated",
        escrow=True,
        created_at=datetime.utcnow(),
    )
    _MOCK.append(o)
    return o


@router.get("", response_model=list[Order])
def list_orders():
    return _MOCK


@router.post("/{oid}/confirm")
def confirm(oid: str):
    return {"order": oid, "status": "confirmed", "escrow": True}


@router.post("/{oid}/deliver")
def deliver(oid: str):
    return {"order": oid, "status": "delivered", "auto_validate_in_days": 7}


@router.post("/{oid}/validate")
def validate(oid: str):
    return {"order": oid, "status": "validated", "release_in_hours": 24}


@router.post("/{oid}/dispute")
def dispute(oid: str, reason: str):
    return {"order": oid, "status": "disputed", "reason": reason, "arbiter": "admin"}
