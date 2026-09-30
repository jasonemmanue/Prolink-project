from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy import or_, select
from sqlalchemy.orm import Session

from app.core.deps import Page, current_user, optional_user, require_pro
from app.db import get_db, utcnow
from app.models import Follow, Post, PostComment, PostLike, PostSave, Report, User
from app.schemas import (
    CommentIn, CommentOut, PostIn, PostOut, PostUpdate, ReportIn, ReportOut, comment_out, post_out,
)
from app.core.config import settings
from app.services import cache
from app.services.notify import notify, notify_many
from app.services.platform import moderate_text

router = APIRouter(tags=["feed"])


def _visible(db: Session, post_id: str) -> Post:
    p = db.get(Post, post_id)
    if not p or p.hidden:
        raise HTTPException(404, "Publication introuvable")
    return p


def _flags(db: Session, user: User | None, ids: list[str]) -> tuple[set[str], set[str]]:
    if not user or not ids:
        return set(), set()
    liked = set(db.scalars(select(PostLike.post_id).where(PostLike.user_id == user.id,
                                                          PostLike.post_id.in_(ids))))
    saved = set(db.scalars(select(PostSave.post_id).where(PostSave.user_id == user.id,
                                                          PostSave.post_id.in_(ids))))
    return liked, saved


def _render(db: Session, user: User | None, posts: list[Post]) -> list[PostOut]:
    liked, saved = _flags(db, user, [p.id for p in posts])
    return [post_out(p, p.id in liked, p.id in saved) for p in posts]


def _overlay(db: Session, user: User | None, items: list[dict]) -> list[dict]:
    liked, saved = _flags(db, user, [p["id"] for p in items])
    return [{**p, "liked": p["id"] in liked, "saved": p["id"] in saved} for p in items]


@router.get("/feed", response_model=list[PostOut])
def feed(page: Page = Depends(), db: Session = Depends(get_db),
         user: User | None = Depends(optional_user)):
    """Fil : posts publics + posts « abonnés » des pros suivis, sponsorisés en tête."""
    uid = user.id if user else "anon"
    items = cache.cached("feed", f"{uid}:{page.limit}:{page.offset}", 30,
                         lambda: _build_feed(db, user, page))
    return _overlay(db, user, items)


def _build_feed(db: Session, user: User | None, page: Page) -> list[PostOut]:
    followed = []
    if user:
        followed = list(db.scalars(select(Follow.pro_id).where(Follow.follower_id == user.id)))
    stmt = select(Post).where(
        Post.hidden.is_(False),
        or_(Post.scheduled_at.is_(None), Post.scheduled_at <= utcnow()),
        or_(Post.audience == "public", Post.author_id.in_(followed or [""]),
            Post.author_id == (user.id if user else "")),
    ).order_by(Post.sponsored.desc(), Post.created_at.desc())
    return [post_out(p) for p in db.scalars(stmt.limit(page.limit).offset(page.offset)).all()]


@router.post("/posts", response_model=PostOut, status_code=201)
def create_post(payload: PostIn, db: Session = Depends(get_db), user: User = Depends(require_pro)):
    data = payload.model_dump()
    data["text"] = moderate_text(db, data["text"])
    p = Post(author_id=user.id, **data)
    db.add(p)
    db.flush()
    if not payload.scheduled_at:
        bells = list(db.scalars(select(Follow.follower_id).where(Follow.pro_id == user.id,
                                                                 Follow.notify.is_(True))))
        notify_many(db, bells, "follow", f"{user.name} a publié", payload.text[:120], {"post_id": p.id})
    db.commit()
    cache.invalidate("feed")
    db.refresh(p)
    return post_out(p)


@router.get("/posts/{post_id}", response_model=PostOut)
def get_post(post_id: str, db: Session = Depends(get_db), user: User | None = Depends(optional_user)):
    return _render(db, user, [_visible(db, post_id)])[0]


@router.patch("/posts/{post_id}", response_model=PostOut)
def update_post(post_id: str, payload: PostUpdate, db: Session = Depends(get_db),
                user: User = Depends(current_user)):
    p = _visible(db, post_id)
    if p.author_id != user.id:
        raise HTTPException(403, "Vous n'êtes pas l'auteur")
    for k, v in payload.model_dump(exclude_unset=True).items():
        setattr(p, k, moderate_text(db, v) if k == "text" else v)
    db.commit()
    cache.invalidate("feed")
    return post_out(p)


@router.delete("/posts/{post_id}", status_code=204)
def delete_post(post_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = _visible(db, post_id)
    if p.author_id != user.id and user.role != "admin":
        raise HTTPException(403, "Vous n'êtes pas l'auteur")
    db.delete(p)
    db.commit()
    cache.invalidate("feed")


@router.post("/posts/{post_id}/like", response_model=PostOut)
def like(post_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = _visible(db, post_id)
    if not db.scalars(select(PostLike).where(PostLike.post_id == p.id, PostLike.user_id == user.id)).first():
        db.add(PostLike(post_id=p.id, user_id=user.id))
        p.likes_count += 1
        db.commit()
        cache.invalidate("feed")
    return _render(db, user, [p])[0]


@router.delete("/posts/{post_id}/like", response_model=PostOut)
def unlike(post_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = _visible(db, post_id)
    row = db.scalars(select(PostLike).where(PostLike.post_id == p.id, PostLike.user_id == user.id)).first()
    if row:
        db.delete(row)
        p.likes_count = max(0, p.likes_count - 1)
        db.commit()
        cache.invalidate("feed")
    return _render(db, user, [p])[0]


@router.post("/posts/{post_id}/save", response_model=PostOut)
def save(post_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = _visible(db, post_id)
    if not db.scalars(select(PostSave).where(PostSave.post_id == p.id, PostSave.user_id == user.id)).first():
        db.add(PostSave(post_id=p.id, user_id=user.id))
        db.commit()
        cache.invalidate("feed")
    return _render(db, user, [p])[0]


@router.delete("/posts/{post_id}/save", response_model=PostOut)
def unsave(post_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    p = _visible(db, post_id)
    row = db.scalars(select(PostSave).where(PostSave.post_id == p.id, PostSave.user_id == user.id)).first()
    if row:
        db.delete(row)
        db.commit()
        cache.invalidate("feed")
    return _render(db, user, [p])[0]


@router.get("/me/saved", response_model=list[PostOut], tags=["me"])
def my_saved(db: Session = Depends(get_db), user: User = Depends(current_user)):
    posts = db.scalars(select(Post).join(PostSave, PostSave.post_id == Post.id)
                       .where(PostSave.user_id == user.id, Post.hidden.is_(False))
                       .order_by(PostSave.created_at.desc())).all()
    return _render(db, user, posts)


@router.get("/posts/{post_id}/comments", response_model=list[CommentOut])
def comments(post_id: str, page: Page = Depends(), db: Session = Depends(get_db)):
    _visible(db, post_id)
    rows = db.scalars(select(PostComment).where(PostComment.post_id == post_id,
                                                PostComment.hidden.is_(False))
                      .order_by(PostComment.created_at).limit(page.limit).offset(page.offset)).all()
    return [comment_out(c) for c in rows]


@router.post("/posts/{post_id}/comments", response_model=CommentOut, status_code=201)
def add_comment(post_id: str, payload: CommentIn, db: Session = Depends(get_db),
                user: User = Depends(current_user)):
    p = _visible(db, post_id)
    c = PostComment(post_id=p.id, author_id=user.id, text=moderate_text(db, payload.text))
    db.add(c)
    p.comments_count += 1
    if p.author_id != user.id:
        notify(db, p.author_id, "follow", f"{user.name} a commenté", payload.text[:120], {"post_id": p.id})
    db.commit()
    cache.invalidate("feed")
    db.refresh(c)
    return comment_out(c)


@router.delete("/comments/{comment_id}", status_code=204)
def delete_comment(comment_id: str, db: Session = Depends(get_db), user: User = Depends(current_user)):
    """Supprimé par son auteur ou modéré par l'auteur du post (UC-PR-21)."""
    c = db.get(PostComment, comment_id)
    if not c:
        raise HTTPException(404, "Commentaire introuvable")
    post = db.get(Post, c.post_id)
    if user.id not in (c.author_id, post.author_id) and user.role != "admin":
        raise HTTPException(403, "Action non autorisée")
    post.comments_count = max(0, post.comments_count - 1)
    db.delete(c)
    db.commit()
    cache.invalidate("feed")


@router.post("/reports", response_model=ReportOut, status_code=201, tags=["moderation"])
def report(payload: ReportIn, db: Session = Depends(get_db), user: User = Depends(current_user)):
    r = Report(reporter_id=user.id, **payload.model_dump())
    db.add(r)
    db.commit()
    cache.invalidate("feed")
    db.refresh(r)
    return r
