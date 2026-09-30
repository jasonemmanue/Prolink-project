"""Jetons d'accès LiveKit (JWT HS256 au format LiveKit)."""
from datetime import datetime, timedelta, timezone

from jose import jwt

from app.core.config import settings


def access_token(room: str, identity: str, name: str, can_publish: bool) -> dict:
    now = datetime.now(timezone.utc)
    configured = bool(settings.livekit_api_key and settings.livekit_api_secret)
    claims = {
        "iss": settings.livekit_api_key or "devkey",
        "sub": identity,
        "name": name,
        "nbf": int(now.timestamp()),
        "exp": int((now + timedelta(hours=4)).timestamp()),
        "video": {
            "room": room,
            "roomJoin": True,
            "canPublish": can_publish,
            "canSubscribe": True,
            "canPublishData": True,
        },
    }
    token = jwt.encode(claims, settings.livekit_api_secret or "devsecret", algorithm="HS256")
    return {
        "url": settings.livekit_url or "ws://localhost:7880",
        "room": room,
        "token": token,
        "configured": configured,
    }
