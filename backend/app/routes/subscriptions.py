"""FastAPI Router for Pennora Subscription & Premium Gating."""

from __future__ import annotations

import json
import os
from datetime import datetime, timezone, timedelta
from typing import Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/subscription", tags=["Subscriptions"])

# Configurable price (defaults to 99 INR/month)
DEFAULT_PREMIUM_PRICE = float(os.getenv("PREMIUM_MONTHLY_PRICE", "99.0"))
GST_RATE = 0.18

PREMIUM_FEATURES = [
    "Advanced financial analysis",
    "Advanced goal conflict analysis",
    "Advanced what-if scenarios",
    "Detailed reports",
    "Advanced AI explanations",
    "Investment Growth Simulator",
    "Advanced spending insights",
    "Ad-free experience",
]


class SubscriptionResponse(BaseModel):
    isPremium: bool
    tier: str
    status: str
    price: float
    currency: str
    billingCycle: str
    isDemo: bool
    features: list[str]
    startDate: Optional[datetime] = None
    endDate: Optional[datetime] = None


@router.get("", response_model=SubscriptionResponse, summary="Get active subscription status")
def get_subscription_status(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    coll = get_collection("subscriptions")

    sub = coll.find_one({"userId": user_id, "status": "active"})

    if sub and sub.get("tier") == "premium":
        return SubscriptionResponse(
            isPremium=True,
            tier="premium",
            status="active",
            price=float(sub.get("price", DEFAULT_PREMIUM_PRICE)),
            currency=sub.get("currency", "INR"),
            billingCycle=sub.get("billingCycle", "monthly"),
            isDemo=bool(sub.get("isDemo", True)),
            features=PREMIUM_FEATURES,
            startDate=sub.get("startDate"),
            endDate=sub.get("endDate"),
        )

    return SubscriptionResponse(
        isPremium=False,
        tier="free",
        status="active",
        price=DEFAULT_PREMIUM_PRICE,
        currency="INR",
        billingCycle="monthly",
        isDemo=False,
        features=[
            "Manual transactions",
            "Basic categorization",
            "Basic dashboard",
            "Basic goals",
            "Basic goal conflict detection",
            "Basic financial analysis",
        ],
    )


@router.post("/demo-activate", response_model=SubscriptionResponse, summary="Activate Demo Premium")
def activate_demo_premium(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    sub_coll = get_collection("subscriptions")
    rev_coll = get_collection("revenue_events")
    analytics_coll = get_collection("analytics_events")
    now = datetime.now(timezone.utc)
    end_date = now + timedelta(days=30)

    # 1. Update or create subscription
    existing = sub_coll.find_one({"userId": user_id})
    sub_doc = {
        "userId": user_id,
        "tier": "premium",
        "status": "active",
        "price": DEFAULT_PREMIUM_PRICE,
        "currency": "INR",
        "billingCycle": "monthly",
        "isDemo": True,
        "startDate": now,
        "endDate": end_date,
        "updatedAt": now,
    }

    if existing:
        sub_coll.update_one({"_id": existing["_id"]}, {"$set": sub_doc})
    else:
        sub_doc["createdAt"] = now
        sub_coll.insert_one(sub_doc)

    # 2. Record revenue event (clearly marked isDemo=True)
    gross = DEFAULT_PREMIUM_PRICE
    tax = round(gross * GST_RATE, 2)
    net = round(gross - tax, 2)

    rev_coll.insert_one({
        "userId": user_id,
        "revenueSource": "SUBSCRIPTION",
        "eventType": "DEMO_PREMIUM_SUBSCRIPTION",
        "amount": gross,
        "taxAmount": tax,
        "netRevenue": net,
        "currency": "INR",
        "partnerId": None,
        "status": "COMPLETED",
        "isDemo": True,
        "createdAt": now,
    })

    # 3. Record analytics event
    analytics_coll.insert_one({
        "userId": user_id,
        "eventName": "premium_upgrade_completed",
        "properties": json.dumps({"plan": "monthly", "is_demo": True, "price": gross}),
        "isDemo": True,
        "createdAt": now,
    })

    return SubscriptionResponse(
        isPremium=True,
        tier="premium",
        status="active",
        price=DEFAULT_PREMIUM_PRICE,
        currency="INR",
        billingCycle="monthly",
        isDemo=True,
        features=PREMIUM_FEATURES,
        startDate=now,
        endDate=end_date,
    )


@router.post("/cancel", response_model=SubscriptionResponse, summary="Cancel subscription")
def cancel_subscription(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    sub_coll = get_collection("subscriptions")
    now = datetime.now(timezone.utc)

    sub_coll.update_one(
        {"userId": user_id},
        {"$set": {"tier": "free", "status": "cancelled", "updatedAt": now}},
    )

    return SubscriptionResponse(
        isPremium=False,
        tier="free",
        status="cancelled",
        price=DEFAULT_PREMIUM_PRICE,
        currency="INR",
        billingCycle="monthly",
        isDemo=False,
        features=[],
    )
