"""FastAPI Router for Advertisement System."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/ads", tags=["Advertisements"])

SAMPLE_ADS = [
    {
        "id": "ad_fd_rates",
        "title": "Compare High-Yield Fixed Deposits",
        "sponsor": "FinSecure Bank (DEMO)",
        "content": "Lock in guaranteed returns up to 7.8% p.a. on your emergency reserves.",
        "callToAction": "Explore Rates",
        "targetUrl": "https://pennora.demo/partner/finsecure-fd",
        "isDemo": True,
        "label": "DEMO / PROJECTED AD",
    },
    {
        "id": "ad_health_cover",
        "title": "Protect Your Family Health Fund",
        "sponsor": "CareShield (DEMO)",
        "content": "Comprehensive family medical protection starting at ₹499/month.",
        "callToAction": "View Plans",
        "targetUrl": "https://pennora.demo/partner/careshield-health",
        "isDemo": True,
        "label": "DEMO / PROJECTED AD",
    },
    {
        "id": "ad_student_tools",
        "title": "Student Skill Certifications",
        "sponsor": "LearnGrowth Academy (DEMO)",
        "content": "Gain verified industry credentials with subsidized student pricing.",
        "callToAction": "Check Courses",
        "targetUrl": "https://pennora.demo/partner/learngrowth",
        "isDemo": True,
        "label": "DEMO / PROJECTED AD",
    },
]


class AdEventRequest(BaseModel):
    adId: str
    eventType: str = Field(..., description="'impression' or 'click'")


@router.get("", summary="Get advertisement placements for free users")
def get_ads(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    sub_coll = get_collection("subscriptions")
    sub = sub_coll.find_one({"userId": user_id, "status": "active", "tier": "premium"})

    # Premium users are completely ad-free!
    if sub:
        return {
            "isAdFree": True,
            "ads": [],
            "message": "Pennora Premium is active. Enjoy an ad-free experience.",
        }

    return {
        "isAdFree": False,
        "ads": SAMPLE_ADS,
        "notice": "Upgrade to Pennora Premium to remove all advertisements.",
    }


@router.post("/event", status_code=status.HTTP_200_OK, summary="Record ad impression or click")
def record_ad_event(
    payload: AdEventRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)
    ev_type = payload.eventType.lower()

    # Track in analytics events
    analytics_coll = get_collection("analytics_events")
    analytics_coll.insert_one({
        "userId": user_id,
        "eventName": f"ad_{ev_type}",
        "properties": json.dumps({"adId": payload.adId, "is_demo": True}),
        "isDemo": True,
        "createdAt": now,
    })

    # If ad was clicked, track demo projected ad revenue (e.g. ₹2.50 CPC)
    if ev_type == "click":
        rev_coll = get_collection("revenue_events")
        gross = 2.50
        tax = round(gross * 0.18, 2)
        net = round(gross - tax, 2)
        rev_coll.insert_one({
            "userId": user_id,
            "revenueSource": "ADVERTISEMENT",
            "eventType": "DEMO_AD_CLICK",
            "amount": gross,
            "taxAmount": tax,
            "netRevenue": net,
            "currency": "INR",
            "partnerId": payload.adId,
            "status": "COMPLETED",
            "isDemo": True,
            "createdAt": now,
        })

    return {"status": "ok", "eventType": ev_type}
