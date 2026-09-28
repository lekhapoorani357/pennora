"""Household and Family Plan Management Service for Pennora.

Enforces:
- Family subscription ownership
- Maximum family member limit (settings.FAMILY_MAX_MEMBERS)
- Strict privacy boundaries (financial data isolation by default)
- Role-based access control (Owner vs Member)
- Invitation lifecycle (invite, accept, decline, revoke)
"""

from __future__ import annotations

import secrets
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from fastapi import HTTPException, status

from app.config import settings
from app.database import get_collection
from app.dependencies import get_user_subscription


class HouseholdService:
    """Business logic for family household management and privacy isolation."""

    @staticmethod
    def get_user_household(user_id: str) -> Optional[Dict[str, Any]]:
        """Finds the active household for a user, either as owner or active member."""
        member_coll = get_collection("household_members")
        hh_coll = get_collection("households")

        membership = member_coll.find_one({"userId": str(user_id), "status": "active"})
        if not membership:
            # Check if user owns a household directly
            return hh_coll.find_one({"ownerId": str(user_id)})

        return hh_coll.find_one({"_id": membership["householdId"]})

    @staticmethod
    def create_household(user_id: str, name: Optional[str] = None) -> Dict[str, Any]:
        """Creates a household for an owner with an active Family subscription."""
        # 1. Verify family entitlement
        sub = get_user_subscription(user_id)
        if not sub or str(sub.get("tier", "")).lower() != "family":
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Family subscription required to create a family household.",
            )

        # 2. Check if user already owns or belongs to a household
        existing = HouseholdService.get_user_household(user_id)
        if existing:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User already belongs to an active household.",
            )

        now = datetime.now(timezone.utc)
        hh_coll = get_collection("households")
        member_coll = get_collection("household_members")

        household_name = (name or "My Family Household").strip()
        hh_doc = {
            "name": household_name,
            "ownerId": str(user_id),
            "maxMembers": settings.FAMILY_MAX_MEMBERS,
            "isDemo": bool(sub.get("isDemo", True)),
            "createdAt": now,
            "updatedAt": now,
        }
        ins_res = hh_coll.insert_one(hh_doc)
        hh_id = str(ins_res.inserted_id)

        # Add creator as owner member
        member_coll.insert_one({
            "householdId": hh_id,
            "userId": str(user_id),
            "role": "owner",
            "status": "active",
            "shareFinancials": False,  # Strict privacy by default
            "joinedAt": now,
            "updatedAt": now,
        })

        return hh_coll.find_one({"_id": hh_id})

    @staticmethod
    def get_household_details(user_id: str) -> Dict[str, Any]:
        """Returns household details, member list, and invitations for authorized users."""
        household = HouseholdService.get_user_household(user_id)
        if not household:
            return {"household": None, "members": [], "invitations": []}

        hh_id = str(household["_id"])
        member_coll = get_collection("household_members")
        inv_coll = get_collection("household_invitations")
        user_coll = get_collection("users")

        raw_members = list(member_coll.find({"householdId": hh_id, "status": "active"}))
        members = []
        is_owner = str(household["ownerId"]) == str(user_id)

        for m in raw_members:
            u = user_coll.find_one({"_id": str(m["userId"])})
            members.append({
                "_id": str(m["_id"]),
                "userId": str(m["userId"]),
                "role": m.get("role", "member"),
                "status": m.get("status", "active"),
                "shareFinancials": bool(m.get("shareFinancials", False)),
                "fullName": u.get("fullName", "Family Member") if u else "Family Member",
                "email": u.get("email", "") if u else "",
                "joinedAt": m.get("joinedAt"),
            })

        # Only owner sees pending invitations
        invitations = []
        if is_owner:
            invitations = list(inv_coll.find({"householdId": hh_id, "status": "pending"}))

        return {
            "household": household,
            "isOwner": is_owner,
            "members": members,
            "invitations": invitations,
            "maxMembers": household.get("maxMembers", settings.FAMILY_MAX_MEMBERS),
            "currentCount": len(members),
        }

    @staticmethod
    def invite_member(owner_id: str, invitee_email: str) -> Dict[str, Any]:
        """Invites a new member to the family household (Owner only)."""
        email = invitee_email.strip().lower()
        if not email or "@" not in email:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Valid email required for household invitation.",
            )

        household = HouseholdService.get_user_household(owner_id)
        if not household or str(household["ownerId"]) != str(owner_id):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Only the household owner can invite members.",
            )

        hh_id = str(household["_id"])
        member_coll = get_collection("household_members")
        inv_coll = get_collection("household_invitations")
        user_coll = get_collection("users")

        # 1. Enforce configured max members limit
        active_count = len(list(member_coll.find({"householdId": hh_id, "status": "active"})))
        pending_count = len(list(inv_coll.find({"householdId": hh_id, "status": "pending"})))
        max_allowed = int(household.get("maxMembers", settings.FAMILY_MAX_MEMBERS))

        if (active_count + pending_count) >= max_allowed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Household has reached maximum limit of {max_allowed} members (including pending invitations).",
            )

        # 2. Check if invitee is already an active member of this or another household
        invitee_user = user_coll.find_one({"email": email})
        if invitee_user:
            existing_active = member_coll.find_one({"userId": str(invitee_user["_id"]), "status": "active"})
            if existing_active:
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="This user is already an active member of a household.",
                )

        # 3. Check for existing pending invitation
        existing_inv = inv_coll.find_one({
            "householdId": hh_id,
            "inviteeEmail": email,
            "status": "pending",
        })
        if existing_inv:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="A pending invitation already exists for this email.",
            )

        now = datetime.now(timezone.utc)
        code = f"fam_{secrets.token_urlsafe(16)}"
        inv_doc = {
            "householdId": hh_id,
            "invitedByUserId": str(owner_id),
            "inviteeEmail": email,
            "inviteeUserId": str(invitee_user["_id"]) if invitee_user else None,
            "status": "pending",
            "inviteCode": code,
            "expiresAt": now + timedelta(days=7),
            "createdAt": now,
            "updatedAt": now,
        }
        ins_res = inv_coll.insert_one(inv_doc)
        return inv_coll.find_one({"_id": ins_res.inserted_id})

    @staticmethod
    def accept_invitation(user_id: str, user_email: str, invitation_id: str) -> Dict[str, Any]:
        """Accepts an invitation, adding user as active family member."""
        inv_coll = get_collection("household_invitations")
        hh_coll = get_collection("households")
        member_coll = get_collection("household_members")

        inv = inv_coll.find_one({"_id": str(invitation_id)})
        if not inv:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="Invitation not found.",
            )

        if inv.get("status") != "pending":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Invitation is already {inv.get('status')}.",
            )

        # Verify email match
        if inv.get("inviteeEmail", "").lower() != user_email.strip().lower():
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Invitation was sent to a different email address.",
            )

        # Check expiration
        now = datetime.now(timezone.utc)
        expires_at = inv.get("expiresAt")
        if expires_at:
            if isinstance(expires_at, str):
                exp_dt = datetime.fromisoformat(expires_at.replace("Z", "+00:00"))
            else:
                exp_dt = expires_at
            if exp_dt.tzinfo is None:
                exp_dt = exp_dt.replace(tzinfo=timezone.utc)
            if now > exp_dt:
                inv_coll.update_one({"_id": inv["_id"]}, {"$set": {"status": "expired"}})
                raise HTTPException(
                    status_code=status.HTTP_400_BAD_REQUEST,
                    detail="Invitation has expired.",
                )

        hh_id = str(inv["householdId"])
        household = hh_coll.find_one({"_id": hh_id})
        if not household:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Household no longer exists.")

        # Check max limit
        active_count = len(list(member_coll.find({"householdId": hh_id, "status": "active"})))
        max_allowed = int(household.get("maxMembers", settings.FAMILY_MAX_MEMBERS))
        if active_count >= max_allowed:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=f"Household is full (maximum {max_allowed} members reached).",
            )

        # Check if already a member elsewhere
        existing_active = member_coll.find_one({"userId": str(user_id), "status": "active"})
        if existing_active:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="User is already an active member of a household.",
            )

        # Add as member with strict privacy default
        member_coll.insert_one({
            "householdId": hh_id,
            "userId": str(user_id),
            "role": "member",
            "status": "active",
            "shareFinancials": False,
            "joinedAt": now,
            "updatedAt": now,
        })

        # Mark invitation accepted
        inv_coll.update_one(
            {"_id": inv["_id"]},
            {"$set": {"status": "accepted", "inviteeUserId": str(user_id), "updatedAt": now}},
        )

        return {"status": "accepted", "householdId": hh_id, "message": "Successfully joined family household."}

    @staticmethod
    def decline_invitation(user_email: str, invitation_id: str) -> Dict[str, Any]:
        """Declines an invitation."""
        inv_coll = get_collection("household_invitations")
        inv = inv_coll.find_one({"_id": str(invitation_id)})
        if not inv:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Invitation not found.")

        if inv.get("inviteeEmail", "").lower() != user_email.strip().lower():
            raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Unauthorized for this invitation.")

        inv_coll.update_one(
            {"_id": inv["_id"]},
            {"$set": {"status": "declined", "updatedAt": datetime.now(timezone.utc)}},
        )
        return {"status": "declined", "message": "Invitation declined."}

    @staticmethod
    def remove_or_leave_member(requester_id: str, member_id_to_remove: str) -> Dict[str, Any]:
        """Removes a member from household (Owner) or leaves household (Member)."""
        member_coll = get_collection("household_members")
        hh_coll = get_collection("households")

        target_member = member_coll.find_one({"_id": str(member_id_to_remove)})
        if not target_member:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Household member not found.")

        hh_id = str(target_member["householdId"])
        household = hh_coll.find_one({"_id": hh_id})
        if not household:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="Household not found.")

        is_owner = str(household["ownerId"]) == str(requester_id)
        is_self = str(target_member["userId"]) == str(requester_id)

        # If not owner and not self, unauthorized!
        if not is_owner and not is_self:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Unauthorized: Only the household owner or the member themselves can perform this action.",
            )

        # Owner cannot leave their own household without transferring or deleting
        if is_self and target_member.get("role") == "owner":
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail="Household owner cannot leave household. Cancel family subscription or delete household.",
            )

        new_status = "left" if is_self else "removed"
        now = datetime.now(timezone.utc)
        member_coll.update_one(
            {"_id": target_member["_id"]},
            {"$set": {"status": new_status, "updatedAt": now}},
        )

        return {
            "status": new_status,
            "memberId": str(target_member["_id"]),
            "message": f"Member successfully {new_status}.",
        }

    @staticmethod
    def update_financial_sharing(user_id: str, share_financials: bool) -> Dict[str, Any]:
        """Allows a user to explicitly opt-in or opt-out of sharing financials with the household."""
        member_coll = get_collection("household_members")
        membership = member_coll.find_one({"userId": str(user_id), "status": "active"})
        if not membership:
            raise HTTPException(
                status_code=status.HTTP_404_NOT_FOUND,
                detail="No active household membership found.",
            )

        member_coll.update_one(
            {"_id": membership["_id"]},
            {"$set": {"shareFinancials": bool(share_financials), "updatedAt": datetime.now(timezone.utc)}},
        )
        return {
            "shareFinancials": bool(share_financials),
            "message": "Financial sharing preference updated.",
        }

    @staticmethod
    def get_member_private_financials(requester_id: str, target_user_id: str) -> Dict[str, Any]:
        """Enforces strict privacy: checks if requester is allowed to view target's financial profile."""
        if str(requester_id) == str(target_user_id):
            # User viewing their own data is always permitted
            profile_coll = get_collection("financial_profiles")
            prof = profile_coll.find_one({"userId": str(target_user_id)})
            return {"allowed": True, "profile": prof}

        # Check if in same household
        member_coll = get_collection("household_members")
        req_member = member_coll.find_one({"userId": str(requester_id), "status": "active"})
        tgt_member = member_coll.find_one({"userId": str(target_user_id), "status": "active"})

        if not req_member or not tgt_member or str(req_member["householdId"]) != str(tgt_member["householdId"]):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Users do not belong to the same household.",
            )

        # STRICT PRIVACY RULE: Even in the same household, sharing must be explicitly consented
        if not tgt_member.get("shareFinancials", False):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Access denied: Member has not consented to share financial data with the household.",
            )

        profile_coll = get_collection("financial_profiles")
        prof = profile_coll.find_one({"userId": str(target_user_id)})
        return {"allowed": True, "profile": prof}
