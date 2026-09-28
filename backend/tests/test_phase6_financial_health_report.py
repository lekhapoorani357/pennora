"""Phase 6 Test Suite: Financial Health & Growth Report (PDF Generation).

Validates:
1. Premium entitlement gating (free users rejected with HTTP 403).
2. Report purchase creates payment, revenue event (with demo/real separation), and pending report.
3. PDF generation via fpdf2 produces valid %PDF bytes without data fabrication.
4. Missing financial profile data handled safely (marked as None / 'Not available').
5. Report generation and storage updates status to 'completed' with base64 payload.
6. User ownership isolation (User B cannot generate, view, or download User A's report).
7. Download endpoint rejects ungenerated reports with HTTP 409 Conflict.
8. End-to-end flow: purchase -> generate -> download valid PDF with correct media headers.
"""

from datetime import datetime, timezone
import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.database import get_collection
from app.services.report_service import (
    collect_report_data,
    generate_pdf_report,
    purchase_report,
    generate_and_store_report,
)


@pytest.fixture
def client(sqlite_test_database):
    return TestClient(app)


def register_user(client: TestClient, email: str, full_name: str = "Report User") -> dict:
    import hashlib
    phone_suffix = str(abs(hash(email)) % 100000000).zfill(8)
    client.post(
        "/auth/register",
        json={
            "fullName": full_name,
            "email": email,
            "phone": f"91{phone_suffix}",
            "password": "Password123!",
        },
    )
    login_res = client.post(
        "/auth/login",
        json={
            "identifier": email,
            "password": "Password123!",
        },
    )
    assert login_res.status_code == 200, f"Login failed for {email}: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_doc = get_collection("users").find_one({"email": email})
    return {"headers": headers, "user": user_doc, "token": token}


def make_user_premium(user_id: str, tier: str = "premium"):
    """Helper to grant an active premium subscription to a user."""
    sub_coll = get_collection("subscriptions")
    sub_coll.insert_one({
        "_id": f"sub_{user_id}",
        "userId": str(user_id),
        "tier": tier,
        "status": "active",
        "billingCycle": "monthly",
        "createdAt": datetime.now(timezone.utc),
    })


# ==================== 1. ENTITLEMENT & PURCHASE TESTS ====================

def test_purchase_requires_premium(client):
    # Free user attempts to purchase report
    free_user = register_user(client, "free_rep@pennora.com")
    res = client.post("/api/reports/purchase", headers=free_user["headers"], json={"is_demo": True})
    assert res.status_code == 403
    assert "Premium subscription required" in res.json()["detail"]


def test_premium_user_can_purchase_report(client):
    prem_user = register_user(client, "prem_rep@pennora.com")
    make_user_premium(str(prem_user["user"]["_id"]), tier="premium")

    res = client.post("/api/reports/purchase", headers=prem_user["headers"], json={"is_demo": True})
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    rep = data["report"]
    assert rep["userId"] == str(prem_user["user"]["_id"])
    assert rep["status"] == "pending"
    assert rep["isDemo"] is True

    # Verify payment & revenue event in database
    payment = get_collection("payments").find_one({"_id": rep["purchaseId"]})
    assert payment is not None
    assert payment["amount"] == 499.0
    assert payment["isDemo"] is True

    rev = get_collection("revenue_events").find_one({"paymentId": rep["purchaseId"]})
    assert rev is not None
    assert rev["isDemo"] is True
    assert rev["amount"] == 499.0


# ==================== 2. PDF GENERATION & NO FABRICATION ====================

def test_generate_pdf_with_empty_profile(client):
    user = register_user(client, "empty_profile@pennora.com")
    data = collect_report_data(str(user["user"]["_id"]))
    # Profile metrics must be None, NOT fabricated
    assert data["monthlyIncome"] is None
    assert data["monthlyExpenses"] is None
    assert data["savingsRate"] is None
    assert data["healthScore"] is None
    assert len(data["goals"]) == 0

    # PDF generation must succeed cleanly without crashing
    pdf_bytes = generate_pdf_report(data)
    assert isinstance(pdf_bytes, bytes)
    assert len(pdf_bytes) > 1000
    assert pdf_bytes[:4] == b"%PDF"


def test_generate_pdf_with_rich_profile_and_goals(client):
    user = register_user(client, "rich_profile@pennora.com")
    user_id = str(user["user"]["_id"])

    # Insert financial profile
    get_collection("financial_profiles").insert_one({
        "_id": f"prof_{user_id}",
        "userId": user_id,
        "monthlyIncome": 120000.0,
        "monthlyExpenses": 45000.0,
    })

    # Insert goals
    get_collection("goals").insert_one({
        "_id": f"goal1_{user_id}",
        "userId": user_id,
        "name": "Emergency Fund",
        "category": "Safety",
        "targetAmount": 300000.0,
        "currentAmount": 150000.0,
    })

    data = collect_report_data(user_id)
    assert data["monthlyIncome"] == 120000.0
    assert data["monthlyExpenses"] == 45000.0
    assert data["savingsRate"] == 62.5
    assert data["healthScore"] is not None
    assert len(data["goals"]) == 1

    pdf_bytes = generate_pdf_report(data)
    assert isinstance(pdf_bytes, bytes)
    assert pdf_bytes[:4] == b"%PDF"


# ==================== 3. REPORT STORAGE & USER ISOLATION ====================

def test_generate_and_store_report_lifecycle(client):
    user = register_user(client, "store_rep@pennora.com")
    user_id = str(user["user"]["_id"])

    rep_doc = purchase_report(user_id=user_id, is_demo=True)
    report_id = rep_doc["_id"]

    updated = generate_and_store_report(user_id=user_id, report_id=report_id)
    assert updated["status"] == "completed"
    assert updated["pdfBytes"] is not None
    assert len(updated["pdfBytes"]) > 500
    assert updated["generatedAt"] is not None


def test_user_ownership_isolation(client):
    # User A creates a report
    user_a = register_user(client, "usera_rep@pennora.com")
    make_user_premium(str(user_a["user"]["_id"]))
    pur_a = client.post("/api/reports/purchase", headers=user_a["headers"], json={"is_demo": True})
    rep_a_id = pur_a.json()["report"]["_id"]

    # User B attempts to access, generate, or download User A's report
    user_b = register_user(client, "userb_rep@pennora.com")
    make_user_premium(str(user_b["user"]["_id"]))

    # 1. View User A's report metadata -> 403 Forbidden
    res_view = client.get(f"/api/reports/{rep_a_id}", headers=user_b["headers"])
    assert res_view.status_code == 403

    # 2. Trigger generation of User A's report -> 403 Forbidden
    res_gen = client.post(f"/api/reports/{rep_a_id}/generate", headers=user_b["headers"])
    assert res_gen.status_code == 403

    # 3. Download User A's report -> 403 Forbidden
    res_dl = client.get(f"/api/reports/{rep_a_id}/download", headers=user_b["headers"])
    assert res_dl.status_code == 403


def test_download_before_generation_returns_409(client):
    user = register_user(client, "early_dl@pennora.com")
    make_user_premium(str(user["user"]["_id"]))

    pur_res = client.post("/api/reports/purchase", headers=user["headers"])
    rep_id = pur_res.json()["report"]["_id"]

    # Attempt to download while status is still 'pending'
    dl_res = client.get(f"/api/reports/{rep_id}/download", headers=user["headers"])
    assert dl_res.status_code == 409
    assert "not finished generating" in dl_res.json()["detail"]


# ==================== 4. FULL END-TO-END FLOW ====================

def test_full_report_e2e_flow(client):
    user = register_user(client, "full_e2e@pennora.com")
    user_id = str(user["user"]["_id"])
    make_user_premium(user_id)

    # 1. Purchase report
    pur_res = client.post("/api/reports/purchase", headers=user["headers"], json={"is_demo": True})
    assert pur_res.status_code == 200
    report_id = pur_res.json()["report"]["_id"]

    # 2. List reports
    list_res = client.get("/api/reports/", headers=user["headers"])
    assert list_res.status_code == 200
    assert any(r["_id"] == report_id for r in list_res.json()["reports"])

    # 3. Generate report
    gen_res = client.post(f"/api/reports/{report_id}/generate", headers=user["headers"])
    assert gen_res.status_code == 200
    assert gen_res.json()["report"]["status"] == "completed"

    # 4. Download report PDF
    dl_res = client.get(f"/api/reports/{report_id}/download", headers=user["headers"])
    assert dl_res.status_code == 200
    assert dl_res.headers["content-type"] == "application/pdf"
    assert dl_res.content[:4] == b"%PDF"
    assert len(dl_res.content) > 1000
