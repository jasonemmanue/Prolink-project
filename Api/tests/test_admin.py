def test_admin_endpoints_forbidden_for_users(make_user):
    u = make_user()
    for url in ("/admin/dashboard", "/admin/users", "/admin/audit", "/admin/kyc"):
        assert u.get(url).status_code == 403


def test_kyc_levels(pro, admin):
    for kind in ("id_card", "selfie", "registry"):
        assert pro.post("/pros/me/kyc", {"kind": kind, "file_url": f"https://cdn/{kind}.jpg"}).status_code == 201
    queue = admin.get("/admin/kyc").json()
    assert len(queue) == 3
    for doc in queue:
        admin.post(f"/admin/kyc/{doc['id']}", {"decision": "approved"})
    me = pro.get("/auth/me").json()["pro"]
    assert me["kyc_status"] == "approved" and me["verified_level"] == 2
    assert len([a for a in admin.get("/admin/audit").json() if a["action"] == "kyc.approved"]) == 3


def test_suspend_blocks_login(client, make_user, admin):
    u = make_user("Spam", "spam@test.cm")
    admin.post(f"/admin/users/{u.user['id']}/suspend", {"reason": "Spam répété"})
    assert u.get("/auth/me").status_code == 401
    assert client.post("/api/v1/auth/login", json={"login": "spam@test.cm", "password": "Secret123!"}).status_code == 403
    admin.post(f"/admin/users/{u.user['id']}/reactivate")
    assert u.get("/auth/me").status_code == 200


def test_commissions_configurable(buyer, pro, service, admin):
    assert admin.put("/admin/settings/commissions", {"service_pct": 80}).status_code == 422
    admin.put("/admin/settings/commissions", {"service_pct": 12})
    o = buyer.post("/orders", {"service_id": service["id"]}).json()
    assert o["commission_xaf"] == 2_400


def test_campaign_review_and_refund(pro, admin):
    pro.enable_2fa()
    pro.topup(30_000)
    post = pro.post("/posts", {"text": "Promo SARL"}).json()
    c = pro.post("/campaigns", {"target_type": "post", "target_id": post["id"], "daily_budget_xaf": 2000, "days": 5})
    assert c.status_code == 201 and pro.balance()["balance_xaf"] == 20_000
    admin.post(f"/admin/campaigns/{c.json()['id']}/review", {"approve": True})
    assert pro.get(f"/posts/{post['id']}").json()["sponsored"] is True
    stop = pro.post(f"/campaigns/{c.json()['id']}/stop")
    assert stop.json()["status"] == "ended" and pro.balance()["balance_xaf"] == 30_000


def test_broadcast_and_dashboard(make_user, admin, pro):
    make_user("Douala", "d@test.cm", city="Douala")
    make_user("Yaoundé", "y@test.cm", city="Yaoundé")
    r = admin.post("/admin/notifications/broadcast", {"title": "Maintenance", "body": "Ce soir 23h",
                                                      "segment": "city:douala"})
    assert r.json()["recipients"] == 2  # client + pro de Douala
    d = admin.get("/admin/dashboard").json()
    assert d["users_total"] == 4 and d["pros"] == 1
    assert admin.get("/admin/finances/export.csv").status_code == 200
    assert "signups" in admin.get("/admin/analytics").json()


def test_seed_is_idempotent():
    from sqlalchemy import func, select

    from app.db import SessionLocal
    from app.models import Order, User
    from app.seed import seed

    assert seed() is True
    assert seed() is False
    db = SessionLocal()
    assert db.scalar(select(func.count(User.id))) == 17
    assert db.scalar(select(func.count(Order.id))) == 9
    db.close()
