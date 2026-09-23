from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/lives", tags=["lives"])


class Live(BaseModel):
    id: str
    title: str
    pro_id: str
    is_live: bool
    paying: bool
    price_xaf: int
    viewers: int


@router.get("", response_model=list[Live])
def list_lives():
    return [
        Live(id="l1", title="Créer sa SARL en 3 étapes", pro_id="p1",
             is_live=True, paying=True, price_xaf=2000, viewers=143),
        Live(id="l2", title="Masterclass cuisine fusion", pro_id="p2",
             is_live=False, paying=True, price_xaf=5000, viewers=0),
    ]


@router.post("/{lid}/ticket")
def buy_ticket(lid: str, method: str = "wallet"):
    return {"live": lid, "ticket": "TCK-" + lid, "method": method, "escrow": True}


@router.post("/{lid}/token")
def livekit_token(lid: str):
    # In production, sign a LiveKit JWT here.
    return {"live": lid, "url": "wss://livekit.example", "token": "signed-jwt-here"}


@router.post("/{lid}/tip")
def send_tip(lid: str, amount_xaf: int):
    return {"live": lid, "amount": amount_xaf, "commission_pct": 10}
