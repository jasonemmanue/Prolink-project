"""Hub WebSocket en mémoire (chat + notifications temps réel).

Une instance d'API suffit pour le MVP ; pour plusieurs réplicas, brancher
Redis pub/sub dans `publish`.
"""
import asyncio
import logging

from anyio.from_thread import run as run_from_thread
from fastapi import WebSocket

log = logging.getLogger("prolink.realtime")


class Hub:
    def __init__(self) -> None:
        self._by_user: dict[str, set[WebSocket]] = {}

    def connect(self, user_id: str, ws: WebSocket) -> None:
        self._by_user.setdefault(user_id, set()).add(ws)

    def disconnect(self, user_id: str, ws: WebSocket) -> None:
        conns = self._by_user.get(user_id)
        if conns:
            conns.discard(ws)
            if not conns:
                self._by_user.pop(user_id, None)

    def is_online(self, user_id: str) -> bool:
        return user_id in self._by_user

    async def publish(self, user_ids: list[str] | set[str], event: dict) -> None:
        for uid in set(user_ids):
            for ws in list(self._by_user.get(uid, ())):
                try:
                    await ws.send_json(event)
                except Exception:  # connexion morte
                    self.disconnect(uid, ws)

    def publish_sync(self, user_ids: list[str] | set[str], event: dict) -> None:
        """Depuis une route `def` (threadpool) : relaie vers la boucle asyncio."""
        if not any(uid in self._by_user for uid in user_ids):
            return
        try:
            run_from_thread(self.publish, user_ids, event)
        except RuntimeError:
            # Pas dans un thread worker AnyIO (ex. script) : tentative best effort.
            try:
                asyncio.get_running_loop().create_task(self.publish(user_ids, event))
            except RuntimeError:
                log.debug("event %s non diffusé (pas de boucle)", event.get("type"))


hub = Hub()
