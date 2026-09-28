"""Phase 1: Premium Business Foundation Test Suite.

Validates:
1. Multi-plan configuration (Free, Premium, Student, Family across Monthly & Annual).
2. Prices originating strictly from configuration.
3. Backend entitlement gate (require_premium returns 403 for Free, 200 for Premium/Trial).
4. Safe demo activation (isDemo=True, recorded in subscriptions, payments, and revenue_events).
5. Single-trial enforcement per user.
6. Clean subscription cancellation.
"""

import pytest
from datetime import datetime, timezone
from fastapi.testclient import TestClient
from sqlalchemy import create_engine

from app.main import app
from app.config import settings
from app.database import set_engine, reset_engine, init_db, get_collection


@pytest.fixture(scope="module")
def client():
    test_engine = create_engine("sqlite:///:memory:", connect_args={"check_same_thread": False})
    set_engine(test_engine)
    init_db(test_engine)

    with TestClient(app) as test_client:
        yield test_client

    reset_engine()


def register_and_login(client: TestClient, email: str) -> dict:
    import hashlib
    phone_suffix = str(abs(hash(email)) % 100000000).zfill(8)
    client.post(
        "/auth/register",
        json={
            "fullName": "Test User",
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
    token = login_res.json()["access_token"]
    return {"Authorization": f"Bearer {token}"}


def test_get_available_plans_from_config(client):
    res = client.get("/api/subscription/plans")
    assert res.status_code == 200
    plans = res.json()
    assert len(plans) == 7

    plan_codes = {p["code"]: p for p in plans}
    assert "free" in plan_codes
    assert "premium_monthly" in plan_codes
    assert "premium_annual" in plan_codes
    assert "student_monthly" in plan_codes
    assert "student_annual" in plan_codes
    assert "family_monthly" in plan_codes
    assert "family_annual" in plan_codes

    # Verify prices match settings configuration
    assert plan_codes["premium_monthly"]["price"] == settings.PLAN_PREMIUM_MONTHLY_PRICE
    assert plan_codes["premium_annual"]["price"] == settings.PLAN_PREMIUM_ANNUAL_PRICE
    assert plan_codes["student_monthly"]["price"] == settings.PLAN_STUDENT_MONTHLY_PRICE
    assert plan_codes["student_annual"]["price"] == settings.PLAN_STUDENT_ANNUAL_PRICE
    assert plan_codes["family_monthly"]["price"] == settings.PLAN_FAMILY_MONTHLY_PRICE
    assert plan_codes["family_annual"]["price"] == settings.PLAN_FAMILY_ANNUAL_PRICE


def test_free_user_blocked_from_premium_feature(client):
    headers = register_and_login(client, "free_user@example.com")

    # 1. Default subscription status is free
    sub_res = client.get("/api/subscription", headers=headers)
    assert sub_res.status_code == 200
    assert sub_res.json()["isPremium"] is False
    assert sub_res.json()["tier"] == "free"

    # 2. Free user attempting to access require_premium endpoint receives 403 Forbidden
    gate_res = client.get("/api/subscription/premium-check", headers=headers)
    assert gate_res.status_code == 403
    assert "Premium subscription required" in gate_res.json()["detail"]


def test_demo_premium_activation_and_revenue_integrity(client):
    headers = register_and_login(client, "demo_buyer@example.com")

    # Activate demo premium
    res = client.post(
        "/api/subscription/demo-activate",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    assert res.status_code == 200
    data = res.json()
    assert data["isPremium"] is True
    assert data["tier"] == "premium"
    assert data["isDemo"] is True
    assert data["price"] == settings.PLAN_PREMIUM_MONTHLY_PRICE

    # Backend entitlement gate now passes with 200 OK
    gate_res = client.get("/api/subscription/premium-check", headers=headers)
    assert gate_res.status_code == 200
    assert gate_res.json()["entitled"] is True

    # Verify Database Integrity
    # Payments table record
    pay_coll = get_collection("payments")
    payment = pay_coll.find_one({"isDemo": True, "status": "paid"})
    assert payment is not None
    assert payment["amount"] == settings.PLAN_PREMIUM_MONTHLY_PRICE
    assert payment["isDemo"] is True
    assert payment["taxAmount"] == round(settings.PLAN_PREMIUM_MONTHLY_PRICE * settings.TAX_RATE, 2)

    # Revenue events table record
    rev_coll = get_collection("revenue_events")
    rev_event = rev_coll.find_one({"revenueSource": "SUBSCRIPTION", "isDemo": True})
    assert rev_event is not None
    assert rev_event["isDemo"] is True


def test_student_and_family_plan_demo_activation(client):
    # Student plan
    student_headers = register_and_login(client, "student_demo@example.com")
    s_res = client.post(
        "/api/subscription/demo-activate",
        json={"planCode": "student_monthly"},
        headers=student_headers,
    )
    assert s_res.status_code == 200
    assert s_res.json()["tier"] == "student"
    assert s_res.json()["isPremium"] is True
    assert s_res.json()["price"] == settings.PLAN_STUDENT_MONTHLY_PRICE

    # Family plan
    family_headers = register_and_login(client, "family_demo@example.com")
    f_res = client.post(
        "/api/subscription/demo-activate",
        json={"planCode": "family_annual"},
        headers=family_headers,
    )
    assert f_res.status_code == 200
    assert f_res.json()["tier"] == "family"
    assert f_res.json()["billingCycle"] == "annual"
    assert f_res.json()["isPremium"] is True
    assert f_res.json()["price"] == settings.PLAN_FAMILY_ANNUAL_PRICE


def test_free_trial_and_single_trial_enforcement(client):
    headers = register_and_login(client, "trial_user@example.com")

    # 1. First trial activation succeeds
    t_res = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    assert t_res.status_code == 200
    t_data = t_res.json()
    assert t_data["isPremium"] is True
    assert t_data["inTrial"] is True
    assert t_data["status"] == "trialing"
    assert t_data["trialEndsAt"] is not None

    # Entitlement gate allows trialing user
    gate_res = client.get("/api/subscription/premium-check", headers=headers)
    assert gate_res.status_code == 200

    # 2. Second trial activation MUST be rejected (400 Bad Request)
    repeat_res = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    assert repeat_res.status_code == 400
    assert "already been activated" in repeat_res.json()["detail"]


def test_subscription_cancellation(client):
    headers = register_and_login(client, "canceller@example.com")
    client.post(
        "/api/subscription/demo-activate",
        json={"planCode": "premium_monthly"},
        headers=headers,
    )
    assert client.get("/api/subscription/premium-check", headers=headers).status_code == 200

    # Cancel subscription
    cancel_res = client.post("/api/subscription/cancel", headers=headers)
    assert cancel_res.status_code == 200
    assert cancel_res.json()["isPremium"] is False
    assert cancel_res.json()["status"] == "cancelled"

    # User is immediately blocked from premium feature again
    assert client.get("/api/subscription/premium-check", headers=headers).status_code == 403
