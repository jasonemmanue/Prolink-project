def test_feed_like_comment_report_and_moderation(make_user, pro, admin):
    admin.post("/admin/keywords", {"word": "arnaque"})
    fan = make_user("Fan", "fan@test.cm")
    fan.post(f"/pros/{pro.user['id']}/follow?notify=true")
    assert fan.get(f"/pros/{pro.user['id']}").json()["is_following"] is True

    p = pro.post("/posts", {"text": "Attention à cette arnaque au notaire", "kind": "article"})
    assert p.status_code == 201 and "******" in p.json()["text"]
    pid = p.json()["id"]
    # L'abonné avec cloche est notifié.
    assert any(n["kind"] == "follow" for n in fan.get("/notifications").json())
    assert fan.post("/posts", {"text": "x"}).status_code == 403  # internaute : pas de publication

    assert fan.post(f"/posts/{pid}/like").json()["likes_count"] == 1
    assert fan.post(f"/posts/{pid}/like").json()["likes_count"] == 1  # idempotent
    assert fan.post(f"/posts/{pid}/save").json()["saved"] is True
    assert len(fan.get("/me/saved").json()) == 1
    c = fan.post(f"/posts/{pid}/comments", {"text": "Merci !"})
    assert c.status_code == 201
    assert fan.get("/feed").json()[0]["comments_count"] == 1
    # Le pro modère un commentaire sur son post (UC-PR-21).
    assert pro.delete(f"/comments/{c.json()['id']}").status_code == 204

    rep = fan.post("/reports", {"target_type": "post", "target_id": pid, "reason": "Contenu choquant"})
    assert rep.status_code == 201
    res = admin.post(f"/admin/reports/{rep.json()['id']}/resolve", {"action": "hide"})
    assert res.json()["status"] == "hidden"
    assert fan.get(f"/posts/{pid}").status_code == 404
    assert any(a["action"] == "report.hide" for a in admin.get("/admin/audit").json())


def test_pro_search_and_services(make_user, pro, service):
    assert pro.post("/pros/me", {"job": "x"}).status_code == 409
    other = make_user("Chef", "chef@test.cm", "pro", job="Chef cuisinier", city="Yaoundé")
    other.post("/services", {"title": "Cours de cuisine", "price_xaf": 25000})
    anon = pro.http
    assert len(anon.get("/api/v1/pros").json()) == 2
    assert [p["name"] for p in anon.get("/api/v1/pros?city=yaoundé").json()] == ["Chef"]
    assert [p["name"] for p in anon.get("/api/v1/pros?q=avoc").json()] == ["Me. Pro"]
    assert len(anon.get("/api/v1/services?q=cuisine").json()) == 1
    # Brouillon invisible publiquement, visible pour son auteur.
    pro.patch(f"/services/{service['id']}", {"status": "draft"})
    assert anon.get(f"/api/v1/pros/{pro.user['id']}/services").json() == []
    assert len(pro.get(f"/pros/{pro.user['id']}/services").json()) == 1
    assert other.patch(f"/services/{service['id']}", {"price_xaf": 1}).status_code == 403


def test_direct_chat_unread_and_websocket(client, make_user, pro):
    a = make_user("Alice", "alice@test.cm")
    conv = a.post("/chat/conversations", {"user_id": pro.user["id"]}).json()
    # Même conversation si on la rouvre.
    assert a.post("/chat/conversations", {"user_id": pro.user["id"]}).json()["id"] == conv["id"]

    m = a.post(f"/chat/conversations/{conv['id']}/messages", {"text": "Hello, I need a quote please"})
    assert m.status_code == 201 and m.json()["lang"] == "en"
    lst = pro.get("/chat/conversations").json()
    assert lst[0]["unread"] == 1 and lst[0]["peer"]["name"] == "Alice"
    pro.post(f"/chat/conversations/{conv['id']}/read")
    assert pro.get("/chat/conversations").json()[0]["unread"] == 0

    outsider = make_user("Eve", "eve@test.cm")
    assert outsider.get(f"/chat/conversations/{conv['id']}/messages").status_code == 403

    with client.websocket_connect(f"/api/v1/chat/ws?token={pro.token}") as ws_pro, \
            client.websocket_connect(f"/api/v1/chat/ws?token={a.token}") as ws_a:
        assert ws_pro.receive_json()["type"] == "ready"
        assert ws_a.receive_json()["type"] == "ready"
        ws_a.send_json({"type": "message", "conversation_id": conv["id"], "text": "Bonjour Maître"})
        got = ws_pro.receive_json()
        assert got["type"] == "message" and got["message"]["text"] == "Bonjour Maître"
        assert got["message"]["lang"] == "fr"


def test_websocket_rejects_bad_token(client):
    import pytest
    from starlette.websockets import WebSocketDisconnect

    with pytest.raises(WebSocketDisconnect):
        with client.websocket_connect("/api/v1/chat/ws?token=nope") as ws:
            ws.receive_json()


def test_paid_group(buyer, pro):
    g = pro.post("/chat/groups", {"title": "Club juridique", "access": "paid", "price_xaf": 5000})
    assert g.status_code == 201
    j = buyer.post(f"/chat/groups/{g.json()['id']}/join")
    assert j.json()["my_status"] == "member"
    assert buyer.balance()["balance_xaf"] == 495_000
    assert pro.balance()["balance_xaf"] == 4_500  # 10 % de commission


def test_paid_live_ticket_token_tip(buyer, pro, make_user):
    r = pro.post("/lives", {"title": "Créer sa SARL", "mode": "paid", "price_xaf": 2000})
    assert r.status_code == 402  # pack gratuit
    pro.enable_2fa()
    pro.topup(20_000)
    assert pro.post("/plans/subscribe", {"plan": "premium"}).json()["plan"] == "premium"
    lv = pro.post("/lives", {"title": "Créer sa SARL", "mode": "paid", "price_xaf": 2000}).json()
    assert pro.post(f"/lives/{lv['id']}/start").json()["status"] == "live"

    assert buyer.post(f"/lives/{lv['id']}/token").status_code == 402  # billet requis
    assert buyer.post(f"/lives/{lv['id']}/ticket").json()["has_access"] is True
    tok = buyer.post(f"/lives/{lv['id']}/token").json()
    assert tok["room"] == f"live-{lv['id']}" and tok["token"]
    host = pro.post(f"/lives/{lv['id']}/token").json()
    assert host["token"] != tok["token"]

    tip = buyer.post(f"/lives/{lv['id']}/tip", {"amount_xaf": 1000})
    assert tip.json()["commission_xaf"] == 100
    end = pro.post(f"/lives/{lv['id']}/end", {"replay_policy": "paid", "replay_price_xaf": 1000})
    s = end.json()["summary"]
    assert s["tickets_sold"] == 1 and s["tips_xaf"] == 1000 and s["peak_viewers"] == 1
    # Pro : 20 000 − 9 900 (pack) + 2 000 − 15 % + 1 000 − 10 %
    assert pro.balance()["balance_xaf"] == 20_000 - 9_900 + 1_700 + 900

    late = make_user("Tard", "late@test.cm")
    assert late.get(f"/lives/{lv['id']}").json()["has_access"] is False


def test_replay_policy_editable_after_end(pro):
    lv = pro.post("/lives", {"title": "Atelier SARL", "mode": "free"}).json()
    assert pro.patch(f"/lives/{lv['id']}", {"replay_policy": "none"}).status_code == 200
    pro.post(f"/lives/{lv['id']}/start")
    pro.post(f"/lives/{lv['id']}/end", {"replay_policy": "free"})
    r = pro.patch(f"/lives/{lv['id']}", {"replay_policy": "paid", "replay_price_xaf": 1500})
    assert r.status_code == 200 and r.json()["replay_price_xaf"] == 1500
    assert pro.patch(f"/lives/{lv['id']}", {"title": "Nouveau"}).status_code == 409
