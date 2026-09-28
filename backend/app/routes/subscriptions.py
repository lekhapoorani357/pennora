"""FastAPI Router for Pennora Subscription & Premium Gating.

Supports Free, Premium, Student, and Family plans across Monthly and Annual billing.
All pricing, tax rates, and trial durations originate strictly from app.config.settings.
Enforces backend entitlement gates and safe demo activation.
"""

from __future__ import annotations

import json
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.config import settings
from app.database import get_collection
from app.dependencies import get_current_user, require_premium, get_user_subscription

router = APIRouter(prefix="/api/subscription", tags=["Subscriptions"])

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

FREE_FEATURES = [
    "Manual transactions",
    "Basic categorization",
    "Basic dashboard",
    "Basic goals",
    "Basic goal conflict detection",
    "Basic financial analysis",
]

STUDENT_FEATURES = PREMIUM_FEATURES + [
    "Student-subsidized rate",
    "Career & education savings trackers",
]

FAMILY_FEATURES = PREMIUM_FEATURES + [
    f"Household sharing up to {settings.FAMILY_MAX_MEMBERS} members",
    "Unified family milestone tracking",
    "Strict individual privacy guarantees",
]


def get_available_plans_dict() -> List[Dict[str, Any]]:
    """Generates the system's plan list populated with dynamic pricing from config."""
    return [
        {
            "code": "free",
            "name": "Pennora Free",
            "tier": "free",
            "billingPeriod": "monthly",
            "price": 0.0,
            "currency": "INR",
            "active": True,
            "trialDays": 0,
            "features": FREE_FEATURES,
        },
        {
            "code": "premium_monthly",
            "name": "Pennora Premium (Monthly)",
            "tier": "premium",
            "billingPeriod": "monthly",
            "price": settings.PLAN_PREMIUM_MONTHLY_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": PREMIUM_FEATURES,
        },
        {
            "code": "premium_annual",
            "name": "Pennora Premium (Annual)",
            "tier": "premium",
            "billingPeriod": "annual",
            "price": settings.PLAN_PREMIUM_ANNUAL_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": PREMIUM_FEATURES,
        },
        {
            "code": "student_monthly",
            "name": "Pennora Student (Monthly)",
            "tier": "student",
            "billingPeriod": "monthly",
            "price": settings.PLAN_STUDENT_MONTHLY_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": STUDENT_FEATURES,
        },
        {
            "code": "student_annual",
            "name": "Pennora Student (Annual)",
            "tier": "student",
            "billingPeriod": "annual",
            "price": settings.PLAN_STUDENT_ANNUAL_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": STUDENT_FEATURES,
        },
        {
            "code": "family_monthly",
            "name": "Pennora Family (Monthly)",
            "tier": "family",
            "billingPeriod": "monthly",
            "price": settings.PLAN_FAMILY_MONTHLY_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": FAMILY_FEATURES,
        },
        {
            "code": "family_annual",
            "name": "Pennora Family (Annual)",
            "tier": "family",
            "billingPeriod": "annual",
            "price": settings.PLAN_FAMILY_ANNUAL_PRICE,
            "currency": "INR",
            "active": True,
            "trialDays": settings.TRIAL_DURATION_DAYS,
            "features": FAMILY_FEATURES,
        },
    ]


class PlanResponse(BaseModel):
    code: str
    name: str
    tier: str
    billingPeriod: str
    price: float
    currency: str
    active: bool
    trialDays: int
    features: List[str]


class SubscriptionResponse(BaseModel):
    isPremium: bool
    tier: str
    planId: Optional[str] = None
    status: str
    price: float
    currency: str
    billingCycle: str
    isDemo: bool
    inTrial: bool = False
    trialEndsAt: Optional[datetime] = None
    startDate: Optional[datetime] = None
    endDate: Optional[datetime] = None
    features: List[str]


class DemoActivateRequest(BaseModel):
    planCode: Optional[str] = "premium_monthly"
    tier: Optional[str] = None
    billingPeriod: Optional[str] = "monthly"


class TrialActivateRequest(BaseModel):
    planCode: Optional[str] = "premium_monthly"


@router.get("/plans", response_model=List[PlanResponse], summary="Get available subscription plans")
def get_plans():
    """Returns all available subscription plans with prices from configuration."""
    plans = get_available_plans_dict()
    # Ensure plans table is populated
    coll = get_collection("plans")
    for p in plans:
        existing = coll.find_one({"code": p["code"]})
        if not existing:
            doc = dict(p)
            doc["featureFlags"] = json.dumps(p["features"])
            del doc["features"]
            coll.insert_one(doc)
    return plans


@router.get("", response_model=SubscriptionResponse, summary="Get active subscription status")
@router.get("/status", response_model=SubscriptionResponse, summary="Get active subscription status alias")
def get_subscription_status(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    sub = get_user_subscription(user_id)
    now = datetime.now(timezone.utc)

    if sub:
        tier = sub.get("tier", "free")
        sub_status = sub.get("status", "active")
        trial_ends = sub.get("trialEndsAt")

        in_trial = False
        if sub_status == "trialing":
            in_trial = True
            if trial_ends:
                t_dt = trial_ends if isinstance(trial_ends, datetime) else datetime.fromisoformat(str(trial_ends).replace("Z", "+00:00"))
                if t_dt.tzinfo is None:
                    t_dt = t_dt.replace(tzinfo=timezone.utc)
                if now > t_dt:
                    # Trial expired
                    sub_status = "expired"
                    tier = "free"
                    in_trial = False

        is_prem = tier in ("premium", "student", "family") and sub_status in ("active", "trialing")

        features_map = {
            "free": FREE_FEATURES,
            "premium": PREMIUM_FEATURES,
            "student": STUDENT_FEATURES,
            "family": FAMILY_FEATURES,
        }

        return SubscriptionResponse(
            isPremium=is_prem,
            tier=tier,
            planId=sub.get("planId"),
            status=sub_status,
            price=float(sub.get("price", settings.PLAN_PREMIUM_MONTHLY_PRICE)),
            currency=sub.get("currency", "INR"),
            billingCycle=sub.get("billingCycle", "monthly"),
            isDemo=bool(sub.get("isDemo", True)),
            inTrial=in_trial,
            trialEndsAt=trial_ends,
            startDate=sub.get("startDate"),
            endDate=sub.get("endDate"),
            features=features_map.get(tier, PREMIUM_FEATURES),
        )

    return SubscriptionResponse(
        isPremium=False,
        tier="free",
        planId="free",
        status="active",
        price=0.0,
        currency="INR",
        billingCycle="monthly",
        isDemo=False,
        inTrial=False,
        features=FREE_FEATURES,
    )


@router.post("/demo-activate", response_model=SubscriptionResponse, summary="Activate Demo Subscription")
def activate_demo_subscription(
    payload: Optional[DemoActivateRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """Activates a safe demo subscription for development and testing.

    MUST mark isDemo = True. It NEVER represents a real payment.
    """
    user_id = str(current_user["_id"])
    sub_coll = get_collection("subscriptions")
    payment_coll = get_collection("payments")
    rev_coll = get_collection("revenue_events")
    analytics_coll = get_collection("analytics_events")
    now = datetime.now(timezone.utc)

    # Resolve plan
    plan_code = (payload.planCode if payload and payload.planCode else "premium_monthly").lower()
    plans = {p["code"]: p for p in get_available_plans_dict()}
    chosen_plan = plans.get(plan_code) or plans["premium_monthly"]

    tier = chosen_plan["tier"]
    cycle = chosen_plan["billingPeriod"]
    price = chosen_plan["price"]
    duration_days = 365 if cycle == "annual" else 30
    end_date = now + timedelta(days=duration_days)

    # 1. Update or create subscription with isDemo = True
    sub_doc = {
        "userId": user_id,
        "planId": plan_code,
        "tier": tier,
        "status": "active",
        "price": price,
        "currency": "INR",
        "billingCycle": cycle,
        "isDemo": True,
        "startDate": now,
        "endDate": end_date,
        "trialEndsAt": None,
        "updatedAt": now,
    }

    existing = sub_coll.find_one({"userId": user_id})
    if existing:
        sub_coll.update_one({"_id": existing["_id"]}, {"$set": sub_doc})
        sub_id = str(existing["_id"])
    else:
        sub_doc["createdAt"] = now
        res = sub_coll.insert_one(sub_doc)
        sub_id = str(res.inserted_id)

    # 2. Record demo payment in payments table
    gross = price
    tax = round(gross * settings.TAX_RATE, 2)
    net = round(gross - tax, 2)

    payment_coll.insert_one({
        "userId": user_id,
        "subscriptionId": sub_id,
        "amount": gross,
        "currency": "INR",
        "gatewayRef": f"demo_pay_{int(now.timestamp())}",
        "status": "paid",
        "taxAmount": tax,
        "netAmount": net,
        "isDemo": True,
        "createdAt": now,
        "updatedAt": now,
    })

    # 3. Record revenue event (clearly marked isDemo=True)
    rev_coll.insert_one({
        "userId": user_id,
        "revenueSource": "SUBSCRIPTION",
        "eventType": f"DEMO_{tier.upper()}_SUBSCRIPTION",
        "amount": gross,
        "taxAmount": tax,
        "netRevenue": net,
        "currency": "INR",
        "partnerId": None,
        "status": "COMPLETED",
        "isDemo": True,
        "createdAt": now,
    })

    # 4. Record analytics event (non-sensitive)
    analytics_coll.insert_one({
        "userId": user_id,
        "eventName": "premium_upgrade_completed",
        "properties": json.dumps({
            "plan": plan_code,
            "tier": tier,
            "billingCycle": cycle,
            "is_demo": True,
            "price": gross,
        }),
        "isDemo": True,
        "createdAt": now,
    })

    return SubscriptionResponse(
        isPremium=True,
        tier=tier,
        planId=plan_code,
        status="active",
        price=price,
        currency="INR",
        billingCycle=cycle,
        isDemo=True,
        inTrial=False,
        features=chosen_plan["features"],
        startDate=now,
        endDate=end_date,
    )


@router.post("/trial-activate", response_model=SubscriptionResponse, summary="Activate free trial")
def activate_free_trial(
    payload: Optional[TrialActivateRequest] = None,
    current_user: dict = Depends(get_current_user),
):
    """Activates a free trial (default 14 days).

    Strict business rule: One trial per user account.
    """
    user_id = str(current_user["_id"])
    sub_coll = get_collection("subscriptions")
    analytics_coll = get_collection("analytics_events")
    now = datetime.now(timezone.utc)

    # Enforce: ONE TRIAL PER USER
    prior_trial = analytics_coll.find_one({"userId": user_id, "eventName": "trial_started"})
    if prior_trial:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Trial has already been activated once for this account. Please select a plan to continue.",
        )

    plan_code = (payload.planCode if payload and payload.planCode else "premium_monthly").lower()
    plans = {p["code"]: p for p in get_available_plans_dict()}
    chosen_plan = plans.get(plan_code) or plans["premium_monthly"]
    tier = chosen_plan["tier"]

    # Student eligibility enforcement
    from app.services.student_service import StudentService
    student_status = StudentService.get_student_status(current_user)

    if tier == "student" and not student_status["isEligible"]:
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail=(
                "Student eligibility required to activate the Student subsidized trial. "
                "Please verify your student email (.edu, .ac.in) or enable demo mode."
            ),
        )

    trial_days = settings.STUDENT_TRIAL_DAYS if tier == "student" else settings.TRIAL_DURATION_DAYS
    trial_ends = now + timedelta(days=trial_days)

    sub_doc = {
        "userId": user_id,
        "planId": plan_code,
        "tier": chosen_plan["tier"],
        "status": "trialing",
        "price": chosen_plan["price"],
        "currency": "INR",
        "billingCycle": chosen_plan["billingPeriod"],
        "isDemo": True,
        "startDate": now,
        "endDate": trial_ends,
        "trialEndsAt": trial_ends,
        "updatedAt": now,
    }

    existing = sub_coll.find_one({"userId": user_id})
    if existing:
        sub_coll.update_one({"_id": existing["_id"]}, {"$set": sub_doc})
    else:
        sub_doc["createdAt"] = now
        sub_coll.insert_one(sub_doc)

    analytics_coll.insert_one({
        "userId": user_id,
        "eventName": "trial_started",
        "properties": json.dumps({"plan": plan_code, "trial_days": trial_days, "is_demo": True}),
        "isDemo": True,
        "createdAt": now,
    })

    return SubscriptionResponse(
        isPremium=True,
        tier=chosen_plan["tier"],
        planId=plan_code,
        status="trialing",
        price=chosen_plan["price"],
        currency="INR",
        billingCycle=chosen_plan["billingPeriod"],
        isDemo=True,
        inTrial=True,
        trialEndsAt=trial_ends,
        features=chosen_plan["features"],
        startDate=now,
        endDate=trial_ends,
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
        planId="free",
        status="cancelled",
        price=0.0,
        currency="INR",
        billingCycle="monthly",
        isDemo=False,
        inTrial=False,
        features=FREE_FEATURES,
    )


@router.get("/premium-check", summary="Test endpoint for require_premium verification")
def check_premium_entitlement(current_user: dict = Depends(require_premium)):
    """Protected endpoint demonstrating backend enforcement of premium access.

    Returns HTTP 200 for Premium/Student/Family/Trialing users; HTTP 403 for Free users.
    """
    return {
        "status": "ok",
        "entitled": True,
        "userId": str(current_user["_id"]),
        "message": "Premium entitlement successfully verified by backend.",
    }


class VerifyStudentRequest(BaseModel):
    studentEmail: Optional[str] = None
    institutionName: Optional[str] = None
    isDemoSelfDeclared: bool = False


@router.get("/student-status", summary="Get student verification and trial eligibility status")
def get_student_status(current_user: dict = Depends(get_current_user)):
    from app.services.student_service import StudentService
    return StudentService.get_student_status(current_user)


@router.post("/verify-student", summary="Verify student status via edu email or self-declared demo")
def verify_student_status(
    payload: VerifyStudentRequest,
    current_user: dict = Depends(get_current_user),
):
    from app.services.student_service import StudentService
    user_id = str(current_user["_id"])
    user_email = str(current_user.get("email", ""))
    return StudentService.verify_student(
        user_id=user_id,
        current_email=user_email,
        student_email=payload.studentEmail,
        institution=payload.institutionName,
        is_demo_self_declared=payload.isDemoSelfDeclared,
    )


class CreateOrderRequest(BaseModel):
    planCode: str = Field(..., description="Plan code to purchase (e.g. premium_monthly, family_annual)")


class SimulateCheckoutRequest(BaseModel):
    orderId: str = Field(..., description="Order ID to simulate gateway payment completion for")


@router.post("/create-order", summary="Create checkout order via configured payment gateway")
def create_payment_order(
    payload: CreateOrderRequest,
    current_user: dict = Depends(get_current_user),
):
    """Creates a pending payment order.

    The Flutter client receives this order, presents the checkout interface,
    and awaits the backend webhook fulfillment. The client NEVER marks payments paid directly.
    """
    from app.services.payment_service import PaymentService

    user_id = str(current_user["_id"])

    # If student plan, check student eligibility
    plans = {p["code"]: p for p in get_available_plans_dict()}
    chosen_plan = plans.get(payload.planCode)
    if chosen_plan and chosen_plan.get("tier") == "student":
        from app.services.student_service import StudentService
        student_status = StudentService.get_student_status(current_user)
        if not student_status["isEligible"]:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Student eligibility required to purchase the Student subsidized plan. Please verify student status.",
            )

    svc = PaymentService()
    return svc.create_checkout_order(user_id=user_id, plan_code=payload.planCode)


from fastapi import Request


@router.post("/webhook", summary="Asynchronous gateway webhook receiver")
async def payment_webhook(request: Request):
    """Processes gateway payment webhooks with cryptographic signature verification.

    IDEMPOTENT: If replayed, does NOT create duplicate payments, duplicate subscriptions, or duplicate revenue!
    """
    from app.services.payment_service import PaymentService

    raw_body = await request.body()
    signature = request.headers.get("x-razorpay-signature") or request.headers.get("x-webhook-signature")

    try:
        payload = json.loads(raw_body.decode("utf-8")) if raw_body else {}
    except Exception:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Malformed JSON in webhook body.",
        )

    svc = PaymentService()
    return svc.process_webhook(raw_body=raw_body, signature=signature, event_payload=payload)


@router.post("/demo-simulate-checkout", summary="Simulate full payment gateway checkout flow")
def simulate_demo_checkout(
    payload: SimulateCheckoutRequest,
    current_user: dict = Depends(get_current_user),
):
    """Simulates gateway checkout callback with valid signature for development/testing."""
    from app.services.payment_service import PaymentService

    user_id = str(current_user["_id"])
    order_id = payload.orderId

    payment_coll = get_collection("payments")
    payment = payment_coll.find_one({"gatewayRef": order_id, "userId": user_id})
    if not payment:
        payment = payment_coll.find_one({"_id": order_id, "userId": user_id})

    if not payment:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Order '{order_id}' not found for user.",
        )

    mock_event = {
        "event": "payment.captured",
        "orderId": order_id,
        "paymentId": f"pay_sim_{int(datetime.now(timezone.utc).timestamp())}",
        "amount": payment["amount"],
        "currency": payment.get("currency", "INR"),
        "status": "paid",
    }
    raw_bytes = json.dumps(mock_event).encode("utf-8")

    svc = PaymentService()
    return svc.process_webhook(
        raw_body=raw_bytes,
        signature="demo_valid_signature",
        event_payload=mock_event,
    )

