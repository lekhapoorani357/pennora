"""Phase 4 Test Suite: Student Role & Trial Model.

Validates:
1. Configurable educational domain verification (.edu, .ac.in, .edu.in)
2. Distinction between verified .edu eligibility vs self-declared demo eligibility
3. Rejection of ineligible non-edu student claims without demo flag
4. Ineligible user blocked from student trial & student checkout order
5. Student trial activation with configurable duration (settings.STUDENT_TRIAL_DAYS = 30)
6. Strict duplicate trial prevention (one trial per user account)
7. Automatic loss of entitlement upon trial expiry
8. Paid student subscription distinction (active vs trialing)
9. Client-side bypass protection
"""

from datetime import datetime, timezone, timedelta
import pytest
from fastapi.testclient import TestClient

from app.config import settings
from app.database import get_collection
from app.main import app


@pytest.fixture
def client(sqlite_test_database):
    return TestClient(app)


def register_user(client: TestClient, email: str, full_name: str = "Test User") -> dict:
    """Helper to register and login, returning auth headers and user doc."""
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


def test_educational_domain_eligibility_and_verification(client):
    # 1. User registered with .edu domain is auto-verified
    edu_user = register_user(client, "student_scholar@harvard.edu", "Harvard Scholar")
    res1 = client.get("/api/subscription/student-status", headers=edu_user["headers"])
    assert res1.status_code == 200
    data1 = res1.json()
    assert data1["isEligible"] is True
    assert data1["isVerified"] is True
    assert data1["isDemo"] is False

    # 2. User registered with .ac.in domain is auto-verified
    iit_user = register_user(client, "researcher@iitb.ac.in", "IITB Researcher")
    res2 = client.get("/api/subscription/student-status", headers=iit_user["headers"])
    assert res2.status_code == 200
    assert res2.json()["isEligible"] is True

    # 3. Regular user with gmail is unverified initially
    regular = register_user(client, "regular_person@gmail.com")
    res3 = client.get("/api/subscription/student-status", headers=regular["headers"])
    assert res3.status_code == 200
    assert res3.json()["isEligible"] is False

    # 4. Regular user verifies via separate educational email
    verify_res = client.post(
        "/api/subscription/verify-student",
        json={
            "studentEmail": "student.alias@stanford.edu",
            "institutionName": "Stanford University",
        },
        headers=regular["headers"],
    )
    assert verify_res.status_code == 200
    assert verify_res.json()["isVerified"] is True
    assert verify_res.json()["verificationStatus"] == "verified_edu"

    # Status check confirms eligibility
    res4 = client.get("/api/subscription/student-status", headers=regular["headers"])
    assert res4.json()["isEligible"] is True


def test_self_declared_demo_student_eligibility(client):
    user = register_user(client, "demo_student@example.com")

    # Ineligible domain without demo flag fails
    fail_res = client.post(
        "/api/subscription/verify-student",
        json={"studentEmail": "demo_student@example.com", "isDemoSelfDeclared": False},
        headers=user["headers"],
    )
    assert fail_res.status_code == 400
    assert "not from an authorized educational domain" in fail_res.json()["detail"]

    # Ineligible domain with explicit isDemoSelfDeclared = True succeeds
    demo_res = client.post(
        "/api/subscription/verify-student",
        json={
            "studentEmail": "demo_student@example.com",
            "institutionName": "Global Open University",
            "isDemoSelfDeclared": True,
        },
        headers=user["headers"],
    )
    assert demo_res.status_code == 200
    assert demo_res.json()["verificationStatus"] == "self_declared_demo"
    assert demo_res.json()["isDemo"] is True
    assert demo_res.json()["isVerified"] is False


def test_ineligible_user_blocked_from_student_trial_and_purchase(client):
    regular = register_user(client, "non_student@gmail.com")

    # 1. Attempt to activate student trial -> Blocked
    trial_block = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "student_monthly"},
        headers=regular["headers"],
    )
    assert trial_block.status_code == 403
    assert "Student eligibility required" in trial_block.json()["detail"]

    # 2. Attempt to create order for student plan -> Blocked
    order_block = client.post(
        "/api/subscription/create-order",
        json={"planCode": "student_annual"},
        headers=regular["headers"],
    )
    assert order_block.status_code == 403
    assert "Student eligibility required" in order_block.json()["detail"]


def test_student_trial_activation_and_duration(client):
    student = register_user(client, "grad_student@mit.edu")

    # 1. Activate student trial
    res = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "student_monthly"},
        headers=student["headers"],
    )
    assert res.status_code == 200
    data = res.json()
    assert data["isPremium"] is True
    assert data["tier"] == "student"
    assert data["status"] == "trialing"
    assert data["inTrial"] is True

    # Verify duration matches settings.STUDENT_TRIAL_DAYS (30 days vs 14 days default)
    start_dt = datetime.fromisoformat(data["startDate"].replace("Z", "+00:00"))
    end_dt = datetime.fromisoformat(data["endDate"].replace("Z", "+00:00"))
    duration_days = (end_dt - start_dt).days
    assert duration_days == settings.STUDENT_TRIAL_DAYS

    # Passes entitlement check
    gate_res = client.get("/api/subscription/premium-check", headers=student["headers"])
    assert gate_res.status_code == 200
    assert gate_res.json()["entitled"] is True


def test_duplicate_trial_prevention(client):
    student = register_user(client, "one_trial_only@oxford.edu")

    # 1st trial activation
    res1 = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "student_monthly"},
        headers=student["headers"],
    )
    assert res1.status_code == 200

    # 2nd trial activation attempt -> Strictly blocked
    res2 = client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "student_monthly"},
        headers=student["headers"],
    )
    assert res2.status_code == 400
    assert "Trial has already been activated once" in res2.json()["detail"]


def test_automatic_loss_of_entitlement_upon_trial_expiry(client):
    student = register_user(client, "expiring_student@berkeley.edu")

    # Activate trial
    client.post(
        "/api/subscription/trial-activate",
        json={"planCode": "student_monthly"},
        headers=student["headers"],
    )
    assert client.get("/api/subscription/premium-check", headers=student["headers"]).status_code == 200

    # Simulate time passing beyond trial expiration
    past_time = datetime.now(timezone.utc) - timedelta(hours=2)
    sub_coll = get_collection("subscriptions")
    sub_coll.update_one(
        {"userId": str(student["user"]["_id"])},
        {"$set": {"trialEndsAt": past_time, "endDate": past_time}},
    )

    # Entitlement check immediately rejects expired trial
    gate_expired = client.get("/api/subscription/premium-check", headers=student["headers"])
    assert gate_expired.status_code == 403

    # Status check reflects expired state
    status_res = client.get("/api/subscription", headers=student["headers"])
    assert status_res.status_code == 200
    assert status_res.json()["isPremium"] is False
    assert status_res.json()["inTrial"] is False


def test_paid_student_subscription_flow(client):
    student = register_user(client, "paying_student@iitd.ac.in")

    # 1. Create order for student annual plan
    order_res = client.post(
        "/api/subscription/create-order",
        json={"planCode": "student_annual"},
        headers=student["headers"],
    )
    assert order_res.status_code == 200
    order_data = order_res.json()
    assert order_data["amount"] == settings.PLAN_STUDENT_ANNUAL_PRICE

    # 2. Simulate payment completion
    sim_res = client.post(
        "/api/subscription/demo-simulate-checkout",
        json={"orderId": order_data["orderId"]},
        headers=student["headers"],
    )
    assert sim_res.status_code == 200

    # 3. Status is active (paid), NOT trialing
    status_res = client.get("/api/subscription", headers=student["headers"])
    assert status_res.status_code == 200
    assert status_res.json()["isPremium"] is True
    assert status_res.json()["tier"] == "student"
    assert status_res.json()["status"] == "paid" or status_res.json()["status"] == "active"
    assert status_res.json()["inTrial"] is False
    assert status_res.json()["price"] == settings.PLAN_STUDENT_ANNUAL_PRICE


def test_client_bypass_prevention(client):
    # Unauthenticated user cannot access student status or trial activation
    assert client.get("/api/subscription/student-status").status_code == 403 or client.get("/api/subscription/student-status").status_code == 401
    assert client.post("/api/subscription/trial-activate", json={"planCode": "student_monthly"}).status_code in (401, 403)
