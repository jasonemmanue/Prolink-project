"""Translation endpoint used by the mobile app chat (Alibaba-style).

MVP: proxies LibreTranslate (self-hosted or public) with graceful fallback.
"""
import httpx
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel

from app.core.config import settings

router = APIRouter(prefix="/translate", tags=["translate"])


class TranslateIn(BaseModel):
    text: str
    source: str = "auto"  # 'auto' | 'fr' | 'en'
    target: str  # 'fr' | 'en'


class TranslateOut(BaseModel):
    text: str
    detected_source: str
    provider: str


_LOCAL_MAP = {
    "bonjour": "hello",
    "merci": "thank you",
    "oui": "yes",
    "non": "no",
    "le prix est": "the price is",
    "je suis disponible": "i am available",
}


def _local_fallback(text: str, target: str) -> str:
    out = text
    if target == "en":
        for fr, en in _LOCAL_MAP.items():
            out = out.replace(fr, en)
    else:
        for fr, en in _LOCAL_MAP.items():
            out = out.replace(en, fr)
    return out


@router.post("", response_model=TranslateOut)
async def translate(payload: TranslateIn):
    if not payload.text.strip():
        raise HTTPException(400, "empty text")
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            r = await client.post(
                f"{settings.translation_base_url}/translate",
                json={
                    "q": payload.text,
                    "source": payload.source,
                    "target": payload.target,
                    "format": "text",
                },
            )
            if r.status_code == 200:
                data = r.json()
                return TranslateOut(
                    text=data.get("translatedText", payload.text),
                    detected_source=data.get("detectedLanguage", {}).get("language", payload.source),
                    provider="libretranslate",
                )
    except Exception:
        pass
    return TranslateOut(
        text=_local_fallback(payload.text, payload.target),
        detected_source=payload.source,
        provider="local-fallback",
    )
