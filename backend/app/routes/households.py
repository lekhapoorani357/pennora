"""FastAPI Router for Pennora Family Plan & Household Management.

Provides:
- Household creation for Family subscribers
- Member invitations with email validation & max limit enforcement
- Invitation acceptance & rejection
- Member removal and self-removal (leaving)
- Strict financial privacy boundaries (no automatic data sharing)
"""

from __future__ import annotations

from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, EmailStr, Field

from app.dependencies import get_current_user
from app.services.household_service import HouseholdService

router = APIRouter(prefix="/api/household", tags=["Households"])


class CreateHouseholdRequest(BaseModel):
    name: Optional[str] = Field(default=None, max_length=100)


class InviteMemberRequest(BaseModel):
    email: EmailStr


class UpdatePrivacyRequest(BaseModel):
    shareFinancials: bool


@router.get("/my-household", summary="Get user's current household details")
def get_my_household(current_user: dict = Depends(get_current_user)):
    """Returns household details, member list, and invitations."""
    user_id = str(current_user["_id"])
    return HouseholdService.get_household_details(user_id)


@router.post("/create", summary="Create a new family household (Family subscribers only)")
def create_household(
    payload: CreateHouseholdRequest,
    current_user: dict = Depends(get_current_user),
):
    """Creates a family household managed by the family subscriber."""
    user_id = str(current_user["_id"])
    return HouseholdService.create_household(user_id=user_id, name=payload.name)


@router.post("/invite", summary="Invite a family member by email (Owner only)")
def invite_member(
    payload: InviteMemberRequest,
    current_user: dict = Depends(get_current_user),
):
    """Invites a user to the family household. Enforces family size limits."""
    owner_id = str(current_user["_id"])
    return HouseholdService.invite_member(owner_id=owner_id, invitee_email=payload.email)


@router.get("/my-invitations", summary="List pending invitations for the authenticated user")
def get_my_invitations(current_user: dict = Depends(get_current_user)):
    """Retrieves all pending invitations sent to current user's email."""
    email = current_user.get("email", "").strip().lower()
    from app.database import get_collection
    inv_coll = get_collection("household_invitations")
    hh_coll = get_collection("households")
    user_coll = get_collection("users")

    invitations = list(inv_coll.find({"inviteeEmail": email, "status": "pending"}))
    results = []
    for inv in invitations:
        hh = hh_coll.find_one({"_id": str(inv["householdId"])})
        owner = user_coll.find_one({"_id": str(inv["invitedByUserId"])}) if inv.get("invitedByUserId") else None
        results.append({
            "_id": str(inv["_id"]),
            "householdId": str(inv["householdId"]),
            "householdName": hh.get("name", "Family Household") if hh else "Family Household",
            "invitedBy": owner.get("fullName", "Family Member") if owner else "Family Member",
            "expiresAt": inv.get("expiresAt"),
            "status": inv.get("status"),
        })
    return {"invitations": results}


@router.post("/invitations/{invitation_id}/accept", summary="Accept household invitation")
def accept_invitation(
    invitation_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Accepts an invitation and joins the family household."""
    user_id = str(current_user["_id"])
    user_email = str(current_user.get("email", ""))
    return HouseholdService.accept_invitation(
        user_id=user_id,
        user_email=user_email,
        invitation_id=invitation_id,
    )


@router.post("/invitations/{invitation_id}/decline", summary="Decline household invitation")
def decline_invitation(
    invitation_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Declines a family household invitation."""
    user_email = str(current_user.get("email", ""))
    return HouseholdService.decline_invitation(
        user_email=user_email,
        invitation_id=invitation_id,
    )


@router.delete("/members/{member_id}", summary="Remove member or leave household")
def remove_or_leave(
    member_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Owner removes member, or member leaves household."""
    requester_id = str(current_user["_id"])
    return HouseholdService.remove_or_leave_member(
        requester_id=requester_id,
        member_id_to_remove=member_id,
    )


@router.patch("/privacy", summary="Update financial sharing preference within household")
def update_privacy(
    payload: UpdatePrivacyRequest,
    current_user: dict = Depends(get_current_user),
):
    """Explicitly enables or disables sharing personal financials with family members."""
    user_id = str(current_user["_id"])
    return HouseholdService.update_financial_sharing(
        user_id=user_id,
        share_financials=payload.shareFinancials,
    )


@router.get("/members/{target_user_id}/financials", summary="Access member financial profile (Privacy Guarded)")
def get_member_financials(
    target_user_id: str,
    current_user: dict = Depends(get_current_user),
):
    """Strict privacy test endpoint: Access is denied unless target has explicitly opted in."""
    requester_id = str(current_user["_id"])
    return HouseholdService.get_member_private_financials(
        requester_id=requester_id,
        target_user_id=target_user_id,
    )
