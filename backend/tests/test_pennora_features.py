"""Comprehensive integration and unit test suite for new Pennora features:
- Role Selection & Profile Persistence
- Deterministic Investment Simulator
- Pennora Premium & Demo Subscription Flow
- Advertisement Delivery & Ad-Free Premium
- Partner / Referral System with Demo Revenue Events
- Non-Sensitive Analytics Tracking
- Protected Admin / Business Dashboard
"""

import pytest
from fastapi.testclient import TestClient
from app.main import app
from app.database import get_database, init_db, reset_engine, set_engine
from sqlalchemy import create_engine
from app.services.investment_service import calculate_lump_sum, calculate_sip


@pytest.fixture(scope="module")
def client():
    # Setup in-memory SQLite database for clean testing
    test_engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    set_engine(test_engine)
    init_db(test_engine)

    with TestClient(app) as test_client:
        yield test_client

    reset_engine()


@pytest.fixture
def auth_header(client):
    # Register and log in a regular user
    reg_res = client.post(
        "/auth/register",
        json={
            "fullName": "Priya Sharma",
            "email": "priya.sharma@example.com",
            "phone": "9876543210",
            "password": "Password123!",
        },
    )
    assert reg_res.status_code in (201, 200, 400)

    login_res = client.post(
        "/auth/login",
        json={
            "identifier": "priya.sharma@example.com",
            "password": "Password123!",
        },
    )
    assert login_res.status_code == 200
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


@pytest.fixture
def admin_auth_header(client):
    # Register and log in an admin user
    client.post(
        "/auth/register",
        json={
            "fullName": "Admin User",
            "email": "admin@pennora.com",
            "phone": "9999999999",
            "password": "AdminPassword123!",
        },
    )
    login_res = client.post(
        "/auth/login",
        json={
            "identifier": "admin@pennora.com",
            "password": "AdminPassword123!",
        },
    )
    token = login_res.json()["access_token"]
    header = {"Authorization": f"Bearer {token}"}
    # Grant admin status via test endpoint
    client.post("/api/admin/grant-admin", headers=header)
    return header


# ─────────────────────────────────────────────────────────────
# 1. Deterministic Math Tests (TEST 4 from specification)
# ─────────────────────────────────────────────────────────────
def test_investment_math_deterministic():
    # Specification: Principal = 20,000, 2 years at 7%, 10%, 12%
    principal = 20000.0
    years = 2.0

    fv_7 = calculate_lump_sum(principal, 7.0, years)
    assert round(fv_7, 2) == 22898.00

    fv_10 = calculate_lump_sum(principal, 10.0, years)
    assert round(fv_10, 2) == 24200.00

    fv_12 = calculate_lump_sum(principal, 12.0, years)
    assert round(fv_12, 2) == 25088.00

    # Test monthly SIP contribution: ₹2,000/mo for 2 years (24 months) at 12%
    fv_sip = calculate_sip(2000.0, 12.0, 24)
    assert fv_sip > 48000.0  # Must be greater than pure principal


# ─────────────────────────────────────────────────────────────
# 2. Role Selection & Profile Tests
# ─────────────────────────────────────────────────────────────
def test_role_selection_and_persistence(client, auth_header):
    # Select Student Role
    res = client.post("/financial-profile/role", json={"role": "student"}, headers=auth_header)
    assert res.status_code == 200
    data = res.json()
    assert data["financialRole"] == "student"

    # Save detailed student profile with roleData
    profile_data = {
        "financialRole": "student",
        "roleData": '{"situation":"hostel","housingCost":5000,"incomeSources":["Pocket money","Freelance"]}',
        "age": 20,
        "occupation": "Student",
        "dependents": 0,
        "monthlyIncome": 12000.0,
        "incomeType": "Pocket money",
        "additionalIncome": 3000.0,
        "currentSavings": 15000.0,
        "fixedExpenses": 6000.0,
        "variableExpenses": 3000.0,
        "monthlyEMI": 0.0,
        "activeLoans": 0,
    }
    save_res = client.post("/financial-profile", json=profile_data, headers=auth_header)
    assert save_res.status_code in (200, 201)
    saved = save_res.json()
    assert saved["financialRole"] == "student"
    assert "hostel" in saved["roleData"]

    # Verify retrieval
    get_res = client.get("/financial-profile", headers=auth_header)
    assert get_res.status_code == 200
    assert get_res.json()["financialRole"] == "student"


# ─────────────────────────────────────────────────────────────
# 3. Investment Growth Simulator Endpoint
# ─────────────────────────────────────────────────────────────
def test_investment_options_and_calculator(client, auth_header):
    # Get options
    options_res = client.get("/api/investments/options")
    assert options_res.status_code == 200
    products = options_res.json()["products"]
    assert len(products) >= 4

    # Calculate simulation for ₹20,000, 2 years
    calc_res = client.post(
        "/api/investments/calculate",
        json={
            "principal": 20000.0,
            "monthlyContribution": 1000.0,
            "durationYears": 2.0,
            "category": "ALL",
        },
        headers=auth_header,
    )
    assert calc_res.status_code == 200
    sim = calc_res.json()
    assert sim["principal"] == 20000.0
    assert sim["totalInvested"] == 44000.0  # 20k + (1k * 24)
    assert len(sim["projections"]) >= 4
    assert "goalImpact" in sim
    assert "disclaimer" in sim


# ─────────────────────────────────────────────────────────────
# 4. Premium Gating & Demo Subscription
# ─────────────────────────────────────────────────────────────
def test_premium_subscription_flow(client, auth_header):
    # Free user check
    sub_res = client.get("/api/subscription", headers=auth_header)
    assert sub_res.status_code == 200
    assert sub_res.json()["isPremium"] is False
    assert sub_res.json()["tier"] == "free"

    # Free user sees ads
    ads_res = client.get("/api/ads", headers=auth_header)
    assert ads_res.status_code == 200
    assert ads_res.json()["isAdFree"] is False
    assert len(ads_res.json()["ads"]) > 0

    # Activate Demo Premium
    act_res = client.post("/api/subscription/demo-activate", headers=auth_header)
    assert act_res.status_code == 200
    assert act_res.json()["isPremium"] is True
    assert act_res.json()["tier"] == "premium"
    assert act_res.json()["isDemo"] is True

    # Premium user is now ad-free!
    ads_premium = client.get("/api/ads", headers=auth_header)
    assert ads_premium.status_code == 200
    assert ads_premium.json()["isAdFree"] is True
    assert len(ads_premium.json()["ads"]) == 0


# ─────────────────────────────────────────────────────────────
# 5. Partners & Referral Click Tracking (TEST 6)
# ─────────────────────────────────────────────────────────────
def test_partner_referrals_and_revenue_event(client, auth_header):
    # Get partners
    part_res = client.get("/api/partners")
    assert part_res.status_code == 200
    partners = part_res.json()["partners"]
    assert len(partners) > 0
    assert "DEMO PARTNER" in partners[0]["partnerName"]
    assert "disclosure" in part_res.json()

    # Record partner click
    p_id = partners[0]["_id"]
    click_res = client.post(
        "/api/partners/click",
        json={"partnerId": p_id, "productName": partners[0]["productName"]},
        headers=auth_header,
    )
    assert click_res.status_code == 200
    assert click_res.json()["isDemo"] is True


# ─────────────────────────────────────────────────────────────
# 6. Analytics Events
# ─────────────────────────────────────────────────────────────
def test_analytics_event_logging(client, auth_header):
    log_res = client.post(
        "/api/analytics/events",
        json={
            "eventName": "investment_simulator_opened",
            "properties": {"role": "student"},
            "isDemo": False,
        },
        headers=auth_header,
    )
    assert log_res.status_code == 201

    get_evs = client.get("/api/analytics/events", headers=auth_header)
    assert get_evs.status_code == 200
    names = [e["eventName"] for e in get_evs.json()]
    assert "investment_simulator_opened" in names


# ─────────────────────────────────────────────────────────────
# 7. Protected Admin Dashboard (TEST 7)
# ─────────────────────────────────────────────────────────────
def test_admin_dashboard_access_control(client, auth_header, admin_auth_header):
    # Regular user cannot access admin metrics
    forbidden_res = client.get("/api/admin/metrics", headers=auth_header)
    assert forbidden_res.status_code == 403

    # Admin user can access real metrics
    admin_res = client.get("/api/admin/metrics", headers=admin_auth_header)
    assert admin_res.status_code == 200
    metrics = admin_res.json()

    assert "userMetrics" in metrics
    assert "revenueMetrics" in metrics
    assert "actualRevenue" in metrics["revenueMetrics"]
    assert "demoProjectedRevenue" in metrics["revenueMetrics"]
    assert metrics["userMetrics"]["totalRegisteredUsers"] >= 2
