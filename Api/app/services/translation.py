"""Traduction FR ⇄ EN : LibreTranslate/DeepL avec repli local."""
import re

import httpx

from app.core.config import settings

_LOCAL_MAP = {
    "bonjour": "hello",
    "bonsoir": "good evening",
    "merci": "thank you",
    "oui": "yes",
    "non": "no",
    "le prix est": "the price is",
    "je suis disponible": "i am available",
    "comment puis-je vous aider": "how can i help you",
    "devis": "quote",
    "commande": "order",
}

_EN_HINTS = {"the", "is", "i", "you", "need", "for", "and", "hello", "please", "quote", "thanks"}
_FR_HINTS = {"le", "la", "les", "je", "vous", "pour", "et", "bonjour", "merci", "une", "des", "est"}


def detect(text: str) -> str:
    words = set(re.findall(r"[a-zàâçéèêëîïôûùüÿœ']+", text.lower()))
    return "en" if len(words & _EN_HINTS) > len(words & _FR_HINTS) else "fr"


def _local(text: str, target: str) -> str:
    out = text
    for fr, en in _LOCAL_MAP.items():
        src, dst = (fr, en) if target == "en" else (en, fr)
        out = re.sub(re.escape(src), dst, out, flags=re.IGNORECASE)
    return out


async def translate(text: str, source: str, target: str) -> dict:
    detected = detect(text) if source == "auto" else source
    if detected == target:
        return {"text": text, "detected_source": detected, "provider": "none"}
    try:
        async with httpx.AsyncClient(timeout=8) as client:
            r = await client.post(
                f"{settings.translation_base_url}/translate",
                json={"q": text, "source": source, "target": target, "format": "text"},
            )
            if r.status_code == 200:
                data = r.json()
                return {
                    "text": data.get("translatedText", text),
                    "detected_source": data.get("detectedLanguage", {}).get("language", detected),
                    "provider": settings.translation_provider,
                }
    except Exception:
        pass
    return {"text": _local(text, target), "detected_source": detected, "provider": "local-fallback"}
