from fastapi import APIRouter

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/dashboard")
def dashboard_kpis():
    return {
        "pros_verified": 4218,
        "active_users_30d": 41320,
        "orders_30d": 12480,
        "lives_live_now": 26,
        "revenue_mtd_xaf": 64_000_000,
    }


@router.post("/pros/{pid}/validate-kyc")
def validate_kyc(pid: str, decision: str):
    return {"pro": pid, "decision": decision}


@router.post("/orders/{oid}/release-manual")
def release_manual(oid: str):
    return {"order": oid, "action": "released_manual"}


@router.post("/categories")
def upsert_category(name: str, active: bool = True):
    return {"name": name, "active": active}


@router.post("/moderation/keywords")
def add_keyword(word: str):
    return {"keyword": word, "added": True}
