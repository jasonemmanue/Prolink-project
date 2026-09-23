from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/pros", tags=["pros"])


class Pro(BaseModel):
    id: str
    name: str
    job: str
    category: str
    city: str
    rating: float
    followers: int
    verified_level: int
    bio: str


_MOCK = [
    Pro(id="p1", name="Me. Aïcha Nkomo", job="Avocate d'affaires",
        category="Droit & Justice", city="Douala", rating=4.9, followers=2431,
        verified_level=3, bio="Avocate au barreau, 12 ans XP."),
    Pro(id="p2", name="Chef Landry Mbappé", job="Chef cuisinier",
        category="Gastronomie & Événementiel", city="Yaoundé", rating=4.8, followers=1820,
        verified_level=2, bio="Traiteur événements."),
    Pro(id="p3", name="Ing. Franck Talla", job="Développeur mobile",
        category="Digital & Tech", city="Douala", rating=4.7, followers=987,
        verified_level=1, bio="Flutter/React 6 ans XP."),
]


@router.get("", response_model=list[Pro])
def list_pros(category: str | None = None, city: str | None = None, q: str | None = None):
    items = _MOCK
    if category:
        items = [p for p in items if p.category == category]
    if city:
        items = [p for p in items if p.city.lower() == city.lower()]
    if q:
        items = [p for p in items if q.lower() in p.name.lower() or q.lower() in p.job.lower()]
    return items


@router.get("/{pro_id}", response_model=Pro)
def get_pro(pro_id: str):
    return next((p for p in _MOCK if p.id == pro_id), _MOCK[0])


@router.post("/{pro_id}/follow")
def follow(pro_id: str, notify: bool = False):
    return {"pro": pro_id, "following": True, "notify": notify}


@router.post("/{pro_id}/kyc")
def submit_kyc(pro_id: str):
    return {"pro": pro_id, "status": "submitted", "review_within_hours": 72}
