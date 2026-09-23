"""ProLink FastAPI backend — REST + WebSockets.

MVP scope covers auth, catalog, orders (with escrow), chat, translation,
live streaming (LiveKit token), payments (CinetPay/Mobile Money) and admin.
"""
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.core.config import settings
from app.api.v1.routes import (
    auth, pros, feed, services, orders, chat, translate,
    lives, wallet, admin, notifications,
)

app = FastAPI(
    title="ProLink API",
    version="1.0.0",
    description="Marketplace sociale multi-services pour professionnels africains.",
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
    return {"name": "ProLink API", "version": "1.0.0", "status": "ok"}

@app.get("/health", tags=["health"])
def health():
    return {"status": "ok"}

for r in (auth, pros, feed, services, orders, chat, translate,
          lives, wallet, admin, notifications):
    app.include_router(r.router, prefix="/api/v1")
