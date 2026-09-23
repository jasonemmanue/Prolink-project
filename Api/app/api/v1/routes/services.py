from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/services", tags=["services"])


class Service(BaseModel):
    id: str
    pro_id: str
    title: str
    description: str
    price_xaf: int
    pricing_type: str
    duration: str
    modality: str
    cancellation: str


@router.get("", response_model=list[Service])
def catalog(pro_id: str | None = None):
    items = [
        Service(id="s1", pro_id="p1", title="Consultation juridique 30 min",
                description="Entretien téléphonique ou visio.",
                price_xaf=15000, pricing_type="fixed", duration="30 min",
                modality="remote", cancellation="flexible"),
        Service(id="s2", pro_id="p1", title="Création de SARL",
                description="Pack complet immatriculation.",
                price_xaf=250000, pricing_type="from", duration="2 semaines",
                modality="mixed", cancellation="standard"),
    ]
    return [s for s in items if not pro_id or s.pro_id == pro_id]


@router.post("")
def create_service(payload: dict):
    return {"id": "s-new", **payload}
