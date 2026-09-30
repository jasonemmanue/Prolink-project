import pytest

from app.services import cache

pytestmark = pytest.mark.skipif(not cache.ping(), reason="Redis indisponible")


def test_health_reports_cache(client):
    assert client.get("/health").json()["cache"] == "ok"


def test_pros_list_cached_and_invalidated_on_follow(make_user, pro):
    fan = make_user("Fan", "fan@test.cm")
    first = fan.get("/pros").json()
    assert first[0]["followers_count"] == 0 and first[0]["is_following"] is False
    assert cache.client().keys("pl:pros:*")  # la liste est bien en cache

    fan.post(f"/pros/{pro.user['id']}/follow")
    after = fan.get("/pros").json()[0]
    # Invalidation : le compteur est à jour, et le drapeau personnel est superposé.
    assert after["followers_count"] == 1 and after["is_following"] is True
    other = make_user("Autre", "autre@test.cm")
    assert other.get("/pros").json()[0]["is_following"] is False


def test_feed_like_visible_despite_cache(make_user, pro):
    p = pro.post("/posts", {"text": "Bonjour"}).json()
    fan = make_user("Fan", "fan@test.cm")
    assert fan.get("/feed").json()[0]["likes_count"] == 0
    fan.post(f"/posts/{p['id']}/like")
    item = fan.get("/feed").json()[0]
    assert item["likes_count"] == 1 and item["liked"] is True


def test_service_update_invalidates_search(pro, service):
    assert pro.http.get("/api/v1/services").json()[0]["price_xaf"] == 20000
    pro.patch(f"/services/{service['id']}", {"price_xaf": 25000})
    assert pro.http.get("/api/v1/services").json()[0]["price_xaf"] == 25000


def test_otp_rate_limited(client):
    for _ in range(5):
        assert client.post("/api/v1/auth/otp/send", json={"target": "+237677", "purpose": "login"}).status_code == 200
    r = client.post("/api/v1/auth/otp/send", json={"target": "+237677", "purpose": "login"})
    assert r.status_code == 429
