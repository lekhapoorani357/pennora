"""Phase 3 Test Suite: Family Plan Tier & Privacy Model.

Validates:
1. Household creation for Family subscribers
2. Non-family user blocked from household creation
3. Invitation creation and email delivery representation
4. Invitation acceptance and Family entitlement inheritance
5. Duplicate invitation prevention
6. Maximum member limit enforcement (settings.FAMILY_MAX_MEMBERS)
7. Unauthorized invite & remove attempts (Owner vs Member RBAC)
8. Member leaving voluntarily and losing family entitlement
9. Owner removing member and revoking family entitlement
10. Strict financial privacy isolation (no auto-sharing; explicit consent required)
"""

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


def activate_family_plan(client: TestClient, headers: dict):
    """Activates a demo family plan for the user."""
    res = client.post(
        "/api/subscription/demo-activate",
        json={"planCode": "family_annual"},
        headers=headers,
    )
    assert res.status_code == 200


def test_household_creation_family_vs_non_family(client):
    # Free user attempts to create household -> Must be blocked
    free_u = register_user(client, "free_owner@example.com")
    res_block = client.post(
        "/api/household/create",
        json={"name": "The Free Family"},
        headers=free_u["headers"],
    )
    assert res_block.status_code == 403
    assert "Family subscription required" in res_block.json()["detail"]

    # Family subscriber creates household -> Success
    fam_u = register_user(client, "family_owner@example.com")
    activate_family_plan(client, fam_u["headers"])

    res_ok = client.post(
        "/api/household/create",
        json={"name": "The Henderson Family"},
        headers=fam_u["headers"],
    )
    assert res_ok.status_code == 200
    data = res_ok.json()
    assert data["name"] == "The Henderson Family"
    assert data["ownerId"] == str(fam_u["user"]["_id"])
    assert data["maxMembers"] == settings.FAMILY_MAX_MEMBERS

    # Cannot create second household
    res_dup = client.post(
        "/api/household/create",
        json={"name": "Another Household"},
        headers=fam_u["headers"],
    )
    assert res_dup.status_code == 400


def test_invitation_lifecycle_and_entitlement_inheritance(client):
    # 1. Owner creates household
    owner = register_user(client, "owner_inviter@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Inviter Household"}, headers=owner["headers"])

    # 2. Member registers as free user
    member = register_user(client, "invitee_spouse@example.com", "Spouse User")

    # Member is free initially
    gate_before = client.get("/api/subscription/premium-check", headers=member["headers"])
    assert gate_before.status_code == 403

    # 3. Owner invites member
    invite_res = client.post(
        "/api/household/invite",
        json={"email": "invitee_spouse@example.com"},
        headers=owner["headers"],
    )
    assert invite_res.status_code == 200
    inv_data = invite_res.json()
    inv_id = inv_data["_id"]
    assert inv_data["status"] == "pending"

    # 4. Invitee checks incoming invitations
    my_invs = client.get("/api/household/my-invitations", headers=member["headers"])
    assert my_invs.status_code == 200
    inv_list = my_invs.json()["invitations"]
    assert len(inv_list) == 1
    assert inv_list[0]["_id"] == inv_id

    # 5. Invitee accepts invitation
    accept_res = client.post(f"/api/household/invitations/{inv_id}/accept", headers=member["headers"])
    assert accept_res.status_code == 200
    assert accept_res.json()["status"] == "accepted"

    # 6. VERIFY FAMILY ENTITLEMENT INHERITANCE
    # Member now passes require_premium gate!
    gate_after = client.get("/api/subscription/premium-check", headers=member["headers"])
    assert gate_after.status_code == 200
    assert gate_after.json()["entitled"] is True

    # Member status reports inherited family tier
    status_after = client.get("/api/subscription/status", headers=member["headers"])
    assert status_after.status_code == 200
    assert status_after.json()["isPremium"] is True
    assert status_after.json()["tier"] == "family"


def test_duplicate_invitation_prevention(client):
    owner = register_user(client, "owner_dup@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Dup Test"}, headers=owner["headers"])

    # 1st invite
    res1 = client.post(
        "/api/household/invite",
        json={"email": "duplicate_target@example.com"},
        headers=owner["headers"],
    )
    assert res1.status_code == 200

    # 2nd invite with same email while pending -> Must reject
    res2 = client.post(
        "/api/household/invite",
        json={"email": "duplicate_target@example.com"},
        headers=owner["headers"],
    )
    assert res2.status_code == 400
    assert "pending invitation already exists" in res2.json()["detail"].lower()


def test_max_family_member_limit_enforced(client):
    owner = register_user(client, "owner_limit@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Max Limit Test"}, headers=owner["headers"])

    # Max members is settings.FAMILY_MAX_MEMBERS (e.g. 5)
    # Owner counts as 1. So 4 more invitations are allowed.
    max_invites = settings.FAMILY_MAX_MEMBERS - 1
    for i in range(max_invites):
        res = client.post(
            "/api/household/invite",
            json={"email": f"member_slot_{i}@example.com"},
            headers=owner["headers"],
        )
        assert res.status_code == 200

    # Next invite exceeds limit -> Must be rejected
    res_overflow = client.post(
        "/api/household/invite",
        json={"email": "member_overflow@example.com"},
        headers=owner["headers"],
    )
    assert res_overflow.status_code == 400
    assert "maximum limit" in res_overflow.json()["detail"].lower()


def test_rbac_unauthorized_invite_and_remove(client):
    # Setup owner + member
    owner = register_user(client, "owner_rbac@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "RBAC Test"}, headers=owner["headers"])

    member = register_user(client, "regular_member@example.com")
    inv = client.post(
        "/api/household/invite",
        json={"email": "regular_member@example.com"},
        headers=owner["headers"],
    ).json()
    client.post(f"/api/household/invitations/{inv['_id']}/accept", headers=member["headers"])

    # Regular member attempts to invite someone -> Must be rejected (Owner only)
    res_unauth_invite = client.post(
        "/api/household/invite",
        json={"email": "unauthorized_target@example.com"},
        headers=member["headers"],
    )
    assert res_unauth_invite.status_code == 403
    assert "Only the household owner" in res_unauth_invite.json()["detail"]

    # Regular member attempts to remove owner -> Must be rejected
    hh_details = client.get("/api/household/my-household", headers=owner["headers"]).json()
    owner_member_id = [m["_id"] for m in hh_details["members"] if m["role"] == "owner"][0]

    res_unauth_remove = client.delete(
        f"/api/household/members/{owner_member_id}",
        headers=member["headers"],
    )
    assert res_unauth_remove.status_code == 403


def test_member_leaving_and_loss_of_entitlement(client):
    owner = register_user(client, "owner_leave@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Leave Test"}, headers=owner["headers"])

    member = register_user(client, "leaving_member@example.com")
    inv = client.post(
        "/api/household/invite",
        json={"email": "leaving_member@example.com"},
        headers=owner["headers"],
    ).json()
    client.post(f"/api/household/invitations/{inv['_id']}/accept", headers=member["headers"])

    # Verify member has entitlement
    assert client.get("/api/subscription/premium-check", headers=member["headers"]).status_code == 200

    # Member leaves
    hh_details = client.get("/api/household/my-household", headers=member["headers"]).json()
    member_record_id = [m["_id"] for m in hh_details["members"] if m["userId"] == str(member["user"]["_id"])][0]

    leave_res = client.delete(f"/api/household/members/{member_record_id}", headers=member["headers"])
    assert leave_res.status_code == 200
    assert leave_res.json()["status"] == "left"

    # Member immediately loses family entitlement
    assert client.get("/api/subscription/premium-check", headers=member["headers"]).status_code == 403


def test_owner_removes_member_and_revokes_entitlement(client):
    owner = register_user(client, "owner_removes@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Removal Test"}, headers=owner["headers"])

    member = register_user(client, "removed_member@example.com")
    inv = client.post(
        "/api/household/invite",
        json={"email": "removed_member@example.com"},
        headers=owner["headers"],
    ).json()
    client.post(f"/api/household/invitations/{inv['_id']}/accept", headers=member["headers"])

    assert client.get("/api/subscription/premium-check", headers=member["headers"]).status_code == 200

    hh_details = client.get("/api/household/my-household", headers=owner["headers"]).json()
    member_record_id = [m["_id"] for m in hh_details["members"] if m["userId"] == str(member["user"]["_id"])][0]

    # Owner removes member
    rem_res = client.delete(f"/api/household/members/{member_record_id}", headers=owner["headers"])
    assert rem_res.status_code == 200
    assert rem_res.json()["status"] == "removed"

    # Member immediately loses family entitlement
    assert client.get("/api/subscription/premium-check", headers=member["headers"]).status_code == 403


def test_strict_financial_privacy_isolation_between_members(client):
    """
    CRITICAL PRIVACY TEST:
    Household membership alone NEVER grants access to another member's private financial data.
    Sharing requires explicit user opt-in consent (shareFinancials = True).
    """
    # 1. Setup household with Owner and Member
    owner = register_user(client, "privacy_owner@example.com")
    activate_family_plan(client, owner["headers"])
    client.post("/api/household/create", json={"name": "Privacy Fortress"}, headers=owner["headers"])

    member = register_user(client, "privacy_member@example.com")
    inv = client.post(
        "/api/household/invite",
        json={"email": "privacy_member@example.com"},
        headers=owner["headers"],
    ).json()
    client.post(f"/api/household/invitations/{inv['_id']}/accept", headers=member["headers"])

    # 2. Member creates private financial profile
    member_prof_res = client.post(
        "/financial-profile",
        json={
            "monthlyIncome": 85000.0,
            "monthlyExpenses": 35000.0,
            "currentSavings": 500000.0,
            "riskTolerance": "moderate",
        },
        headers=member["headers"],
    )
    assert member_prof_res.status_code in (200, 201)

    # 3. Owner attempts to view Member's financials
    # Default shareFinancials is False -> MUST return 403 Forbidden!
    member_user_id = str(member["user"]["_id"])
    view_attempt_1 = client.get(
        f"/api/household/members/{member_user_id}/financials",
        headers=owner["headers"],
    )
    assert view_attempt_1.status_code == 403
    assert "Member has not consented to share financial data" in view_attempt_1.json()["detail"]

    # 4. Member EXPLICITLY opts in to share financials with household
    opt_in_res = client.patch(
        "/api/household/privacy",
        json={"shareFinancials": True},
        headers=member["headers"],
    )
    assert opt_in_res.status_code == 200
    assert opt_in_res.json()["shareFinancials"] is True

    # 5. Now Owner can view the shared financial profile
    view_attempt_2 = client.get(
        f"/api/household/members/{member_user_id}/financials",
        headers=owner["headers"],
    )
    assert view_attempt_2.status_code == 200
    assert view_attempt_2.json()["profile"]["monthlyIncome"] == 85000.0

    # 6. Member revokes consent (opt-out)
    opt_out_res = client.patch(
        "/api/household/privacy",
        json={"shareFinancials": False},
        headers=member["headers"],
    )
    assert opt_out_res.status_code == 200

    # 7. Owner is blocked again
    view_attempt_3 = client.get(
        f"/api/household/members/{member_user_id}/financials",
        headers=owner["headers"],
    )
    assert view_attempt_3.status_code == 403
