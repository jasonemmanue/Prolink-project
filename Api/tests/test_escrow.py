"""Séquestre, commissions et portefeuille : l'argent doit toujours tomber juste."""
from datetime import timedelta

from app.db import SessionLocal, utcnow
from app.models import Order
from app.services.orders import release_due_orders


def test_topup_requires_2fa_above_threshold(make_user):
    u = make_user()
    u.topup(60_000)
    r = u.post("/wallet/topup", {"amount_xaf": 60_000, "method": "orange"})
    assert r.status_code == 403 and "Double authentification" in r.json()["detail"]
    u.enable_2fa()
    u.topup(60_000)
    assert u.balance()["balance_xaf"] == 120_000


def test_order_full_cycle_releases_net_to_pro(buyer, pro, service):
    r = buyer.post("/orders", {"service_id": service["id"], "variant": "Premium", "brief": "SARL"})
    assert r.status_code == 201, r.text
    order = r.json()
    assert order["amount_xaf"] == 60_000 and order["commission_xaf"] == 6_000
    assert order["status"] == "pending" and order["escrow_status"] == "held"
    assert buyer.balance() == {**buyer.balance(), "balance_xaf": 440_000, "escrow_xaf": 60_000}
    assert pro.balance()["escrow_xaf"] == 54_000  # net à recevoir

    # Mauvais acteur / mauvais état.
    assert buyer.post(f"/orders/{order['id']}/confirm").status_code == 403
    assert pro.post(f"/orders/{order['id']}/deliver", {}).status_code == 409

    assert pro.post(f"/orders/{order['id']}/confirm").json()["status"] == "in_progress"
    d = pro.post(f"/orders/{order['id']}/deliver", {"message": "Statuts en PJ", "deliverables": ["statuts.pdf"]})
    assert d.json()["status"] == "delivered" and d.json()["auto_release_at"]
    v = buyer.post(f"/orders/{order['id']}/validate")
    assert v.json()["status"] == "completed" and v.json()["escrow_status"] == "released"

    assert buyer.balance()["escrow_xaf"] == 0
    wp = pro.balance()
    assert wp["balance_xaf"] == 54_000 and wp["escrow_xaf"] == 0
    kinds = {t["kind"]: t["amount_xaf"] for t in pro.get("/wallet/transactions").json()}
    assert kinds == {"order_payout": 60_000, "commission": -6_000}

    # Avis unique, note recalculée.
    rv = buyer.post(f"/orders/{order['id']}/review", {"stars": 4, "text": "Bien"})
    assert rv.status_code == 201
    assert buyer.post(f"/orders/{order['id']}/review", {"stars": 5}).status_code == 409
    assert buyer.get(f"/pros/{pro.user['id']}").json()["rating"] == 4.0
    assert pro.post(f"/reviews/{rv.json()['id']}/reply", {"reply": "Merci !"}).json()["reply"] == "Merci !"


def test_insufficient_balance(make_user, pro, service):
    u = make_user()
    r = u.post("/orders", {"service_id": service["id"]})
    assert r.status_code == 402


def test_mobile_money_order_sandbox(make_user, pro, service):
    u = make_user()
    r = u.post("/orders", {"service_id": service["id"], "payment_method": "mtn", "phone": "690000000"})
    assert r.status_code == 201 and r.json()["status"] == "pending"
    assert u.balance() == {**u.balance(), "balance_xaf": 0, "escrow_xaf": 20_000}


def test_cancel_and_decline_refund(buyer, pro, service):
    o1 = buyer.post("/orders", {"service_id": service["id"]}).json()
    assert buyer.post(f"/orders/{o1['id']}/cancel").json()["status"] == "cancelled"
    o2 = buyer.post("/orders", {"service_id": service["id"]}).json()
    assert pro.post(f"/orders/{o2['id']}/decline").json()["escrow_status"] == "refunded"
    b = buyer.balance()
    assert b["balance_xaf"] == 500_000 and b["escrow_xaf"] == 0
    assert pro.balance()["escrow_xaf"] == 0


def test_auto_release_after_72h(buyer, pro, service):
    o = buyer.post("/orders", {"service_id": service["id"]}).json()
    pro.post(f"/orders/{o['id']}/confirm")
    pro.post(f"/orders/{o['id']}/deliver", {})
    db = SessionLocal()
    db.get(Order, o["id"]).delivered_at = utcnow() - timedelta(hours=73)
    db.commit()
    assert release_due_orders(db) == 1
    db.close()
    assert buyer.get(f"/orders/{o['id']}").json()["status"] == "completed"
    assert pro.balance()["balance_xaf"] == 18_000


def test_dispute_split_by_admin_is_audited(buyer, pro, service, admin):
    o = buyer.post("/orders", {"service_id": service["id"], "variant": "Premium"}).json()
    pro.post(f"/orders/{o['id']}/confirm")
    d = buyer.post(f"/orders/{o['id']}/dispute", {"reason": "Livrable non conforme", "remedy": "partial"})
    assert d.status_code == 201
    assert buyer.get(f"/orders/{o['id']}").json()["escrow_status"] == "frozen"
    pro.post(f"/orders/{o['id']}/dispute/messages", {"text": "Je propose une reprise"})

    assert buyer.post(f"/admin/disputes/{d.json()['id']}/resolve",
                      {"resolution": "split", "refund_xaf": 20_000, "note": "x"}).status_code == 403
    r = admin.post(f"/admin/disputes/{d.json()['id']}/resolve",
                   {"resolution": "split", "refund_xaf": 20_000, "note": "Moitié conforme"})
    assert r.status_code == 200 and len(r.json()["events"]) == 3

    # 60 000 : 20 000 remboursés, 40 000 au pro − 10 % de commission.
    assert buyer.balance() == {**buyer.balance(), "balance_xaf": 460_000, "escrow_xaf": 0}
    assert pro.balance() == {**pro.balance(), "balance_xaf": 36_000, "escrow_xaf": 0}
    actions = [a["action"] for a in admin.get("/admin/audit").json()]
    assert "dispute.split" in actions


def test_quote_flow(buyer, pro):
    q = buyer.post("/quotes", {"pro_id": pro.user["id"], "description": "Recouvrement d'une créance de 2 M"})
    assert q.status_code == 201
    qid = q.json()["id"]
    assert buyer.post(f"/quotes/{qid}/accept").status_code == 409  # pas encore chiffré
    rep = pro.post(f"/quotes/{qid}/reply", {"lines": [{"label": "Mise en demeure", "amount_xaf": 50_000},
                                                      {"label": "Audience", "amount_xaf": 100_000}]})
    assert rep.json()["total_xaf"] == 150_000
    o = buyer.post(f"/quotes/{qid}/accept")
    assert o.status_code == 201 and o.json()["amount_xaf"] == 150_000
    assert buyer.get(f"/quotes/{qid}").json()["status"] == "accepted"


def test_withdraw_rules(buyer, pro, service):
    o = buyer.post("/orders", {"service_id": service["id"]}).json()
    pro.post(f"/orders/{o['id']}/confirm")
    pro.post(f"/orders/{o['id']}/deliver", {})
    buyer.post(f"/orders/{o['id']}/validate")  # pro : 18 000
    assert buyer.post("/wallet/withdraw", {"amount_xaf": 5000, "operator": "mtn", "phone": "6",
                                           "otp": "1"}).status_code == 403  # clients exclus
    too_much = pro.post("/wallet/withdraw", {"amount_xaf": 18_000, "operator": "mtn",
                                             "phone": "690", "otp": pro.otp("withdraw")})
    assert too_much.status_code == 402  # 500 XAF minimum laissés
    bad_otp = pro.post("/wallet/withdraw", {"amount_xaf": 10_000, "operator": "mtn", "phone": "690", "otp": "000000"})
    assert bad_otp.status_code == 400
    ok = pro.post("/wallet/withdraw", {"amount_xaf": 10_000, "operator": "orange", "phone": "690",
                                       "otp": pro.otp("withdraw")})
    assert ok.status_code == 201 and ok.json()["amount_xaf"] == -10_000
    assert pro.balance()["balance_xaf"] == 8_000
    csv = pro.get("/wallet/statement.csv")
    assert csv.status_code == 200 and "withdraw" in csv.text
