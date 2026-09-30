"""Cache Redis (lecture seule des données publiques) + limitation de débit.

- Clés versionnées par espace de noms : `pl:{ns}:v{n}:{suffixe}`. Invalider un
  espace = incrémenter `pl:ver:{ns}` (O(1), pas de SCAN).
- Si Redis est indisponible, l'API fonctionne normalement sans cache
  (dégradation silencieuse, un seul avertissement dans les logs).
"""
import json
import logging
import time
from collections.abc import Callable
from typing import Any

import redis
from fastapi.encoders import jsonable_encoder

from app.core.config import settings

log = logging.getLogger("prolink.cache")

_client: redis.Redis | None = None
_down_until = 0.0  # après une panne, on réessaie au bout de 30 s


def client() -> redis.Redis | None:
    global _client, _down_until
    if not settings.redis_url or time.monotonic() < _down_until:
        return None
    if _client is None:
        _client = redis.Redis.from_url(settings.redis_url, socket_timeout=0.3,
                                       socket_connect_timeout=0.3, decode_responses=True)
    return _client


def _guard(fn: Callable[[redis.Redis], Any], default: Any = None) -> Any:
    global _down_until
    r = client()
    if r is None:
        return default
    try:
        return fn(r)
    except redis.RedisError as e:
        if _down_until == 0.0 or time.monotonic() >= _down_until:
            log.warning("Redis indisponible (%s) — cache désactivé 30 s", e)
        _down_until = time.monotonic() + 30
        return default


def ping() -> bool:
    return bool(_guard(lambda r: r.ping(), False))


def _key(ns: str, suffix: str) -> str | None:
    ver = _guard(lambda r: r.get(f"pl:ver:{ns}") or "0")
    return None if ver is None else f"pl:{ns}:v{ver}:{suffix}"


def cached(ns: str, suffix: str, ttl: int, compute: Callable[[], Any]) -> Any:
    """Renvoie la valeur en cache ou la calcule (résultat JSON-sérialisable)."""
    key = _key(ns, suffix)
    if key:
        hit = _guard(lambda r: r.get(key))
        if hit is not None:
            return json.loads(hit)
    value = jsonable_encoder(compute())
    if key:
        _guard(lambda r: r.set(key, json.dumps(value), ex=ttl))
    return value


def invalidate(*namespaces: str) -> None:
    for ns in namespaces:
        _guard(lambda r, ns=ns: r.incr(f"pl:ver:{ns}"))


def rate_limit(bucket: str, limit: int, window_s: int) -> bool:
    """True si l'appel est autorisé (fenêtre fixe). Sans Redis : toujours autorisé."""
    def _hit(r: redis.Redis) -> bool:
        key = f"pl:rl:{bucket}:{int(time.time() // window_s)}"
        n = r.incr(key)
        if n == 1:
            r.expire(key, window_s)
        return n <= limit
    return _guard(_hit, True)


def flush_all() -> None:
    """Tests uniquement."""
    _guard(lambda r: r.flushdb())
