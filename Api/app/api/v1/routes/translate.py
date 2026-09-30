"""Traduction utilisée par le chat (style Alibaba : bulle traduite + « Voir l'original »)."""
from fastapi import APIRouter, HTTPException

from app.schemas import TranslateIn, TranslateOut
from app.services.translation import translate as do_translate

router = APIRouter(prefix="/translate", tags=["translate"])


@router.post("", response_model=TranslateOut)
async def translate(payload: TranslateIn):
    if not payload.text.strip():
        raise HTTPException(400, "Texte vide")
    return TranslateOut(**await do_translate(payload.text, payload.source, payload.target))
