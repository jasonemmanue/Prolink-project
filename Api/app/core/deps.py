from fastapi import Depends, HTTPException, Query, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session

from app.core.security import decode_token
from app.db import get_db
from app.models import User

bearer = HTTPBearer(auto_error=False)


def _user_from_token(db: Session, token: str | None) -> User | None:
    if not token:
        return None
    data = decode_token(token)
    if not data:
        return None
    user = db.get(User, data["sub"])
    if not user or not user.is_active:
        return None
    return user


def current_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User:
    user = _user_from_token(db, creds.credentials if creds else None)
    if not user:
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Authentification requise",
                            headers={"WWW-Authenticate": "Bearer"})
    return user


def optional_user(
    creds: HTTPAuthorizationCredentials | None = Depends(bearer),
    db: Session = Depends(get_db),
) -> User | None:
    return _user_from_token(db, creds.credentials if creds else None)


def require_pro(user: User = Depends(current_user)) -> User:
    if user.role not in ("pro", "admin") or (user.role == "pro" and not user.pro):
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Réservé aux comptes professionnels")
    return user


def require_admin(user: User = Depends(current_user)) -> User:
    if user.role != "admin":
        raise HTTPException(status.HTTP_403_FORBIDDEN, "Réservé aux administrateurs")
    return user


class Page:
    """Pagination standard : ?limit=&offset=."""

    def __init__(self, limit: int = Query(20, ge=1, le=100), offset: int = Query(0, ge=0)):
        self.limit = limit
        self.offset = offset
