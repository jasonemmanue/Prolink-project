from fastapi import APIRouter
from pydantic import BaseModel

router = APIRouter(prefix="/feed", tags=["feed"])


class Post(BaseModel):
    id: str
    author_id: str
    text: str
    images: list[str] = []
    likes: int = 0
    comments: int = 0
    sponsored: bool = False


@router.get("", response_model=list[Post])
def feed():
    return [
        Post(id="po1", author_id="p1",
             text="Nouveau : accompagnement complet pour la création d'une SARL.",
             images=["https://images.unsplash.com/photo-1450101499163-c8848c66ca85"],
             likes=128, comments=14, sponsored=True),
        Post(id="po2", author_id="p2",
             text="Retour sur le buffet du mariage Kono.",
             likes=302, comments=41),
    ]


@router.post("/posts")
def create_post(payload: dict):
    return {"id": "po-new", **payload}


@router.post("/posts/{post_id}/like")
def like(post_id: str):
    return {"post": post_id, "liked": True}


@router.post("/posts/{post_id}/report")
def report(post_id: str, reason: str = "spam"):
    return {"post": post_id, "reason": reason, "status": "queued"}
