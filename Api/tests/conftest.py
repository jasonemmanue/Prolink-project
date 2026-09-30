"""Tests d'intégration sur une vraie base PostgreSQL (prolink_test).

Lancement : docker compose run --rm api pytest
"""
import os

# Doit précéder tout import de l'app : bascule sur la base de test.
os.environ["DATABASE_URL"] = os.environ.get(
    "TEST_DATABASE_URL", "postgresql+psycopg2://prolink:prolink@localhost:5432/prolink_test")
os.environ["SEED_DEMO"] = "false"

import pytest  # noqa: E402
from alembic import command  # noqa: E402
from alembic.config import Config  # noqa: E402
from fastapi.testclient import TestClient  # noqa: E402
from sqlalchemy import text  # noqa: E402

from app.core.security import hash_password  # noqa: E402
from app.db import Base, SessionLocal, engine  # noqa: E402
from app.main import app  # noqa: E402
from app.models import User  # noqa: E402


@pytest.fixture(scope="session", autouse=True)
def schema():
    with engine.begin() as conn:
        conn.execute(text("DROP SCHEMA public CASCADE; CREATE SCHEMA public"))
    # Applique la vraie migration (valide aussi le script Alembic).
    command.upgrade(Config(os.path.join(os.path.dirname(__file__), "..", "alembic.ini")), "head")
    yield


@pytest.fixture(autouse=True)
def clean():
    yield
    tables = ", ".join(f'"{t.name}"' for t in Base.metadata.sorted_tables)
    with engine.begin() as conn:
        conn.execute(text(f"TRUNCATE {tables} RESTART IDENTITY CASCADE"))


@pytest.fixture
def client():
    with TestClient(app) as c:
        yield c


class Api:
    """Petit client authentifié pour écrire des scénarios lisibles."""

    def __init__(self, http: TestClient, token: str, user: dict):
        self.http, self.token, self.user = http, token, user

    @property
    def h(self):
        return {"Authorization": f"Bearer {self.token}"}

    def get(self, url, **kw):
        return self.http.get(f"/api/v1{url}", headers=self.h, **kw)

    def post(self, url, json=None, **kw):
        return self.http.post(f"/api/v1{url}", json=json, headers=self.h, **kw)

    def patch(self, url, json=None):
        return self.http.patch(f"/api/v1{url}", json=json, headers=self.h)

    def put(self, url, json=None):
        return self.http.put(f"/api/v1{url}", json=json, headers=self.h)

    def delete(self, url):
        return self.http.delete(f"/api/v1{url}", headers=self.h)

    def otp(self, purpose: str) -> str:
        r = self.post("/auth/otp/send", {"target": "-", "purpose": purpose})
        assert r.status_code == 200, r.text
        return r.json()["dev_code"]

    def enable_2fa(self):
        assert self.post("/auth/2fa/enable", {"target": "-", "purpose": "2fa",
                                             "code": self.otp("2fa")}).status_code == 200

    def topup(self, amount: int):
        r = self.post("/wallet/topup", {"amount_xaf": amount, "method": "mtn", "phone": "690000000"})
        assert r.status_code == 201, r.text
        return r.json()

    def balance(self) -> dict:
        return self.get("/wallet").json()


def register(http: TestClient, name: str, email: str, role: str = "client", **extra) -> Api:
    r = http.post("/api/v1/auth/register", json={"name": name, "email": email, "password": "Secret123!",
                                                 "role": role, **extra})
    assert r.status_code == 201, r.text
    body = r.json()
    return Api(http, body["access_token"], body["user"])


@pytest.fixture
def make_user(client):
    def _make(name="Client Test", email="client@test.cm", role="client", **extra) -> Api:
        return register(client, name, email, role, **extra)
    return _make


@pytest.fixture
def pro(make_user) -> Api:
    return make_user("Me. Pro", "pro@test.cm", "pro", job="Avocate", city="Douala")


@pytest.fixture
def buyer(make_user) -> Api:
    u = make_user("Acheteur", "buyer@test.cm")
    u.enable_2fa()
    u.topup(500_000)
    return u


@pytest.fixture
def admin(client) -> Api:
    db = SessionLocal()
    db.add(User(name="Admin", email="admin@test.cm", password_hash=hash_password("Admin123!"), role="admin"))
    db.commit()
    db.close()
    r = client.post("/api/v1/auth/login", json={"login": "admin@test.cm", "password": "Admin123!"})
    body = r.json()
    return Api(client, body["access_token"], body["user"])


@pytest.fixture
def service(pro) -> dict:
    r = pro.post("/services", {"title": "Consultation juridique", "price_xaf": 20000, "pricing_type": "fixed",
                               "variants": [{"name": "Basic", "price_xaf": 20000},
                                            {"name": "Premium", "price_xaf": 60000}]})
    assert r.status_code == 201, r.text
    return r.json()
