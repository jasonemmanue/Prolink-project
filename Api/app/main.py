"""ProLink FastAPI backend — REST + WebSockets, PostgreSQL."""
import asyncio
import logging
from contextlib import asynccontextmanager

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from sqlalchemy import text
from starlette.concurrency import run_in_threadpool

from app.api.v1.routes import (
    admin, auth, campaigns, chat, feed, lives, notifications, orders, pros, services,
    translate, wallet,
)
from app.core.config import settings
from app.db import SessionLocal
from app.services import cache
from app.services.orders import release_due_orders

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s: %(message)s")
log = logging.getLogger("prolink")


def _auto_release_once() -> int:
    db = SessionLocal()
    try:
        return release_due_orders(db)
    finally:
        db.close()


async def _auto_release_loop() -> None:
    """Toutes les 10 min : libère le séquestre des commandes livrées depuis 72 h."""
    while True:
        try:
            n = await run_in_threadpool(_auto_release_once)
            if n:
                log.info("Séquestre libéré automatiquement pour %d commande(s)", n)
        except Exception:
            log.exception("Échec de la libération automatique")
        await asyncio.sleep(600)


@asynccontextmanager
async def lifespan(_: FastAPI):
    task = asyncio.create_task(_auto_release_loop())
    yield
    task.cancel()


app = FastAPI(
    title="ProLink API",
    version="1.1.0",
    description=(
        "Marketplace sociale multi-services pour professionnels africains.\n\n"
        "Authentification : `POST /api/v1/auth/login` puis bouton **Authorize** avec le "
        "`access_token`. Comptes de démo : voir le README."
    ),
    lifespan=lifespan,
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)


@app.get("/", tags=["health"])
def root():
    return {"name": "ProLink API", "version": app.version, "docs": "/docs"}


@app.get("/health", tags=["health"])
def health():
    db = SessionLocal()
    try:
        db.execute(text("SELECT 1"))
        database = "ok"
    except Exception:
        database = "down"
    finally:
        db.close()
    return {"status": "ok" if database == "ok" else "degraded", "database": database,
            "cache": "ok" if cache.ping() else "off",
            "payments": "sandbox" if settings.payments_sandbox else "cinetpay"}


for r in (auth, pros, feed, services, orders, wallet, chat, translate, lives,
          notifications, campaigns, admin):
    app.include_router(r.router, prefix="/api/v1")
