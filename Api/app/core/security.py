import secrets
from datetime import datetime, timedelta, timezone

from jose import JWTError, jwt
from passlib.context import CryptContext

from app.core.config import settings

# Argon2 (exigence du cahier des charges).
pwd = CryptContext(schemes=["argon2"], deprecated="auto")


def hash_password(p: str) -> str:
    return pwd.hash(p)


def verify_password(plain: str, hashed: str) -> bool:
    try:
        return pwd.verify(plain, hashed)
    except ValueError:
        return False


def _encode(claims: dict, ttl: timedelta) -> str:
    now = datetime.now(timezone.utc)
    return jwt.encode(
        {**claims, "iat": now, "exp": now + ttl},
        settings.jwt_secret,
        algorithm=settings.jwt_algorithm,
    )


def create_access_token(sub: str, role: str) -> str:
    return _encode(
        {"sub": sub, "role": role, "type": "access"},
        timedelta(minutes=settings.access_token_ttl_minutes),
    )


def create_refresh_token(sub: str) -> str:
    return _encode(
        {"sub": sub, "type": "refresh", "jti": secrets.token_hex(8)},
        timedelta(days=settings.refresh_token_ttl_days),
    )


def decode_token(token: str, expected_type: str = "access") -> dict | None:
    try:
        data = jwt.decode(token, settings.jwt_secret, algorithms=[settings.jwt_algorithm])
    except JWTError:
        return None
    if data.get("type") != expected_type:
        return None
    return data


def generate_otp() -> str:
    return f"{secrets.randbelow(1_000_000):06d}"
