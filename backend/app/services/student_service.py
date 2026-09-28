"""Student Role & Eligibility Service for Pennora.

Provides:
- Configurable domain validation (.edu, .ac.in, .edu.in, etc.)
- Clear distinction between verified .edu eligibility vs self-declared/demo eligibility
- Zero document/ID upload requirement
- Enforces student trial eligibility & duration (settings.STUDENT_TRIAL_DAYS)
"""

from __future__ import annotations

from datetime import datetime, timezone
from typing import Any, Dict, Optional
from fastapi import HTTPException, status

from app.config import settings
from app.database import get_collection


class StudentService:
    """Manages student eligibility verification and trial parameters."""

    @staticmethod
    def is_eligible_domain(email: str) -> bool:
        """Evaluates whether an email ends with any allowed educational domain."""
        em = (email or "").strip().lower()
        if "@" not in em:
            return False
        domain_part = em.split("@")[-1]
        for allowed in settings.STUDENT_ALLOWED_DOMAINS:
            target = allowed.lower()
            if target.startswith("."):
                if domain_part.endswith(target.lstrip(".")) or em.endswith(target):
                    return True
            else:
                if domain_part == target or domain_part.endswith(f".{target}"):
                    return True
        return False

    @staticmethod
    def get_student_status(current_user: dict) -> Dict[str, Any]:
        """Returns the user's student verification status and eligibility."""
        user_id = str(current_user["_id"])
        email = str(current_user.get("email", ""))
        user_coll = get_collection("users")
        u = user_coll.find_one({"_id": user_id}) or current_user

        v_status = u.get("studentVerificationStatus", "unverified")
        inst = u.get("studentInstitution")
        v_at = u.get("studentVerifiedAt")
        role = u.get("role", "user")

        # Auto-verify if user registered with educational domain email
        is_edu_domain = StudentService.is_eligible_domain(email)
        if is_edu_domain and v_status == "unverified":
            v_status = "verified_edu"
            domain_inst = email.split("@")[-1]
            inst = inst or f"Institution ({domain_inst})"

        # Check if user has already consumed a trial
        analytics_coll = get_collection("analytics_events")
        prior_trial = analytics_coll.find_one({"userId": user_id, "eventName": "trial_started"})

        is_eligible = (
            v_status in ("verified_edu", "self_declared_demo")
            or is_edu_domain
            or role == "student"
        )

        return {
            "userId": user_id,
            "email": email,
            "isEligible": is_eligible,
            "verificationStatus": v_status,
            "institution": inst,
            "verifiedAt": v_at,
            "isVerified": v_status == "verified_edu" or is_edu_domain,
            "isDemo": v_status == "self_declared_demo",
            "allowedDomains": settings.STUDENT_ALLOWED_DOMAINS,
            "trialDurationDays": settings.STUDENT_TRIAL_DAYS,
            "trialAvailable": prior_trial is None,
        }

    @staticmethod
    def verify_student(
        user_id: str,
        current_email: str,
        student_email: Optional[str] = None,
        institution: Optional[str] = None,
        is_demo_self_declared: bool = False,
    ) -> Dict[str, Any]:
        """Verifies student status via educational email domain or explicit self-declared demo."""
        target_email = (student_email or current_email).strip().lower()
        now = datetime.now(timezone.utc)
        user_coll = get_collection("users")

        is_edu = StudentService.is_eligible_domain(target_email)

        if is_edu:
            # Verified via educational domain
            domain_name = target_email.split("@")[-1]
            inst_name = (institution or f"Institution ({domain_name})").strip()
            user_coll.update_one(
                {"_id": user_id},
                {
                    "$set": {
                        "role": "student",
                        "studentVerificationStatus": "verified_edu",
                        "studentInstitution": inst_name,
                        "studentVerifiedAt": now,
                        "updatedAt": now,
                    }
                },
            )
            return {
                "status": "success",
                "verificationStatus": "verified_edu",
                "isVerified": True,
                "isDemo": False,
                "institution": inst_name,
                "message": f"Successfully verified student eligibility via educational domain ({domain_name}).",
            }

        elif is_demo_self_declared and settings.STUDENT_ALLOW_SELF_DECLARED_DEMO:
            # Self-declared demo for non-production demonstration
            inst_name = (institution or "Demo University").strip()
            user_coll.update_one(
                {"_id": user_id},
                {
                    "$set": {
                        "role": "student",
                        "studentVerificationStatus": "self_declared_demo",
                        "studentInstitution": inst_name,
                        "studentVerifiedAt": now,
                        "updatedAt": now,
                    }
                },
            )
            return {
                "status": "success",
                "verificationStatus": "self_declared_demo",
                "isVerified": False,
                "isDemo": True,
                "institution": inst_name,
                "message": "Self-declared student demo eligibility activated.",
            }

        else:
            raise HTTPException(
                status_code=status.HTTP_400_BAD_REQUEST,
                detail=(
                    f"Email '{target_email}' is not from an authorized educational domain "
                    f"({', '.join(settings.STUDENT_ALLOWED_DOMAINS)}). "
                    "For evaluation without an .edu address, enable isDemoSelfDeclared = true."
                ),
            )
