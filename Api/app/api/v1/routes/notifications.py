from fastapi import APIRouter

router = APIRouter(prefix="/notifications", tags=["notifications"])


@router.post("/token")
def register_fcm_token(token: str, platform: str = "android"):
    return {"stored": True, "platform": platform}


@router.post("/push")
def send_push(title: str, body: str, segment: str | None = None):
    # Real impl uses Firebase Admin SDK.
    return {"queued": True, "segment": segment, "title": title}
