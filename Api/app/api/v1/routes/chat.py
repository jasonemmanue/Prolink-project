from fastapi import APIRouter, WebSocket, WebSocketDisconnect
from pydantic import BaseModel

router = APIRouter(prefix="/chat", tags=["chat"])


class Message(BaseModel):
    id: str
    conversation_id: str
    author_id: str
    text: str
    translated_text: str | None = None


_conns: dict[str, list[WebSocket]] = {}


@router.get("/conversations")
def list_convs():
    return [
        {"id": "c1", "peer": "p1", "last": "Je vous envoie le pack…"},
        {"id": "c2", "peer": "p3", "last": "Ok, 4 écrans + auth Firebase ?"},
    ]


@router.get("/conversations/{cid}/messages")
def messages(cid: str):
    return [
        {"id": "m1", "author_id": "p1", "text": "Bonjour, comment puis-je vous aider ?"},
        {"id": "m2", "author_id": "me", "text": "Hello, I need a quote for creating a SARL."},
        {"id": "m3", "author_id": "p1", "text": "Très bien, le prix est à partir de 250 000 XAF."},
    ]


@router.websocket("/ws/{cid}")
async def ws_chat(websocket: WebSocket, cid: str):
    await websocket.accept()
    _conns.setdefault(cid, []).append(websocket)
    try:
        while True:
            data = await websocket.receive_json()
            for c in _conns[cid]:
                if c is not websocket:
                    await c.send_json(data)
    except WebSocketDisconnect:
        _conns[cid].remove(websocket)
