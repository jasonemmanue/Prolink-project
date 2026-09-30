def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.json()["database"] == "ok"


def test_register_login_refresh_me(client, make_user):
    u = make_user("Emmanuel", "emma@test.cm")
    assert u.user["role"] == "client"
    assert client.post("/api/v1/auth/register", json={
        "name": "Doublon", "email": "emma@test.cm", "password": "Secret123!"}).status_code == 409

    bad = client.post("/api/v1/auth/login", json={"login": "emma@test.cm", "password": "nope"})
    assert bad.status_code == 401
    ok = client.post("/api/v1/auth/login", json={"login": "EMMA@test.cm", "password": "Secret123!"})
    assert ok.status_code == 200
    tokens = ok.json()

    ref = client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["refresh_token"]})
    assert ref.status_code == 200
    # Un access token ne peut pas servir de refresh token.
    assert client.post("/api/v1/auth/refresh", json={"refresh_token": tokens["access_token"]}).status_code == 401

    me = u.patch("/auth/me", {"city": "Yaoundé", "ui_lang": "en", "notification_prefs": {"lives": False}})
    assert me.json()["city"] == "Yaoundé" and me.json()["notification_prefs"] == {"lives": False}
    assert client.get("/api/v1/auth/me").status_code == 401


def test_password_hashed_with_argon2(make_user):
    from sqlalchemy import select

    from app.db import SessionLocal
    from app.models import User

    make_user("Argon", "argon@test.cm")
    db = SessionLocal()
    assert db.scalars(select(User.password_hash).where(User.email == "argon@test.cm")).one().startswith("$argon2")
    db.close()


def test_two_factor_login(client, make_user):
    u = make_user("Deux", "2fa@test.cm")
    u.enable_2fa()
    r = client.post("/api/v1/auth/login", json={"login": "2fa@test.cm", "password": "Secret123!"})
    assert r.status_code == 401 and r.json()["code"] == "2fa_required"
    code = r.json()["dev_code"]
    wrong = client.post("/api/v1/auth/login", json={"login": "2fa@test.cm", "password": "Secret123!", "otp": "000000"})
    assert wrong.status_code == 400
    ok = client.post("/api/v1/auth/login", json={"login": "2fa@test.cm", "password": "Secret123!", "otp": code})
    assert ok.status_code == 200


def test_phone_otp_login(client, make_user):
    make_user("Tel", None, phone="+237699112233")
    code = client.post("/api/v1/auth/otp/send", json={"target": "+237699112233", "purpose": "login"}).json()["dev_code"]
    r = client.post("/api/v1/auth/otp/login", json={"target": "+237699112233", "purpose": "login", "code": code})
    assert r.status_code == 200 and r.json()["user"]["phone_verified"] is True
    # Code à usage unique.
    again = client.post("/api/v1/auth/otp/login", json={"target": "+237699112233", "purpose": "login", "code": code})
    assert again.status_code == 400


def test_become_pro(make_user):
    u = make_user()
    r = u.post("/pros/me", {"job": "Photographe", "bio": "Mariages"})
    assert r.status_code == 201 and r.json()["job"] == "Photographe"
    assert u.get("/auth/me").json()["role"] == "pro"
