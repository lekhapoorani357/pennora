"""FastAPI Router for Partner / Referral Financial Products."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/partners", tags=["Partners & Referrals"])

SEED_PARTNERS = [
    {
        "partnerName": "DEMO PARTNER — FinSecure Bank",
        "productName": "Senior & Regular Fixed Deposit 7.75%",
        "category": "FD",
        "description": "High safety AAA-rated term deposits with monthly or quarterly compounding.",
        "referralUrl": "https://pennora.demo/partner/finsecure-fd",
        "commissionType": "flat",
        "commissionAmountOrRate": 50.0,
        "active": True,
        "disclosure": "Partner/referral relationship may result in revenue for Pennora.",
        "isDemo": True,
    },
    {
        "partnerName": "DEMO PARTNER — IndexGrowth Direct",
        "productName": "Zero-Commission Index Fund Platform",
        "category": "MUTUAL_FUND",
        "description": "Direct mutual fund investing with automated SIP and goal tracking.",
        "referralUrl": "https://pennora.demo/partner/indexgrowth",
        "commissionType": "flat",
        "commissionAmountOrRate": 75.0,
        "active": True,
        "disclosure": "Partner/referral relationship may result in revenue for Pennora.",
        "isDemo": True,
    },
    {
        "partnerName": "DEMO PARTNER — CareShield Life & Health",
        "productName": "Term Life & Comprehensive Family Health Cover",
        "category": "INSURANCE",
        "description": "Pure risk protection cover safeguarding dependents and child education milestones.",
        "referralUrl": "https://pennora.demo/partner/careshield",
        "commissionType": "flat",
        "commissionAmountOrRate": 120.0,
        "active": True,
        "disclosure": "Partner/referral relationship may result in revenue for Pennora.",
        "isDemo": True,
    },
    {
        "partnerName": "DEMO PARTNER — StudentPerks Education",
        "productName": "Student Higher Education Savings Account",
        "category": "OTHER",
        "description": "Special zero-balance savings account with educational benefits and student card cashback.",
        "referralUrl": "https://pennora.demo/partner/studentperks",
        "commissionType": "flat",
        "commissionAmountOrRate": 30.0,
        "active": True,
        "disclosure": "Partner/referral relationship may result in revenue for Pennora.",
        "isDemo": True,
    },
]


class PartnerClickRequest(BaseModel):
    partnerId: str
    productName: Optional[str] = None


@router.get("", summary="Get partner financial product offerings")
def get_partners():
    coll = get_collection("partner_products")
    existing = list(coll.find({}))
    now = datetime.now(timezone.utc)

    if not existing:
        for p in SEED_PARTNERS:
            doc = dict(p)
            doc["createdAt"] = now
            doc["updatedAt"] = now
            coll.insert_one(doc)
        existing = list(coll.find({}))

    for it in existing:
        it["_id"] = str(it["_id"])

    return {
        "partners": existing,
        "disclosure": "Partner/referral relationship may result in revenue for Pennora.",
        "notice": "All partner relationships shown here are DEMO PARTNERS for demonstration purposes.",
    }


@router.post("/click", status_code=status.HTTP_200_OK, summary="Record user interaction with partner product")
def record_partner_click(
    payload: PartnerClickRequest,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    # 1. Log analytics event
    analytics_coll = get_collection("analytics_events")
    analytics_coll.insert_one({
        "userId": user_id,
        "eventName": "partner_product_clicked",
        "properties": json.dumps({"partnerId": payload.partnerId, "productName": payload.productName, "is_demo": True}),
        "isDemo": True,
        "createdAt": now,
    })

    # 2. Record referral revenue event (isDemo=True)
    rev_coll = get_collection("revenue_events")
    gross = 50.0  # demo referral payout
    tax = round(gross * 0.18, 2)
    net = round(gross - tax, 2)

    rev_coll.insert_one({
        "userId": user_id,
        "revenueSource": "PARTNER_REFERRAL",
        "eventType": "DEMO_PARTNER_CLICK_REFERRAL",
        "amount": gross,
        "taxAmount": tax,
        "netRevenue": net,
        "currency": "INR",
        "partnerId": payload.partnerId,
        "status": "COMPLETED",
        "isDemo": True,
        "createdAt": now,
    })

    return {
        "status": "ok",
        "message": "Referral click registered (DEMO).",
        "isDemo": True,
    }
