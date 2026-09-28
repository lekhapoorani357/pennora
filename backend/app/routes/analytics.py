"""FastAPI Router for Non-Sensitive Product Analytics."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user

router = APIRouter(prefix="/api/analytics", tags=["Product Analytics"])

ALLOWED_EVENTS = {
    "user_registered",
    "goal_created",
    "transaction_added",
    "conflict_detected",
    "scenario_created",
    "investment_simulator_opened",
    "premium_page_opened",
    "premium_upgrade_started",
    "premium_upgrade_completed",
    "partner_product_clicked",
    "ad_impression",
    "ad_clicked",
}


class AnalyticsEventCreate(BaseModel):
    eventName: str = Field(..., min_length=2, max_length=100)
    properties: Optional[Dict[str, Any]] = None
    isDemo: bool = False


@router.post("/events", status_code=status.HTTP_201_CREATED, summary="Log a non-sensitive product analytics event")
def log_analytics_event(
    payload: AnalyticsEventCreate,
    current_user: dict = Depends(get_current_user),
):
    user_id = str(current_user["_id"])
    ev_name = payload.eventName.strip()

    # Sanitize properties to prevent sensitive financial data storage in analytics
    safe_props = {}
    if payload.properties:
        for k, v in payload.properties.items():
            if k.lower() not in ("password", "token", "hash", "card", "bankaccount", "secret"):
                safe_props[k] = v

    coll = get_collection("analytics_events")
    now = datetime.now(timezone.utc)
    doc = {
        "userId": user_id,
        "eventName": ev_name,
        "properties": json.dumps(safe_props),
        "isDemo": payload.isDemo,
        "createdAt": now,
    }
    res = coll.insert_one(doc)

    return {"status": "recorded", "id": str(res.inserted_id)}


@router.get("/events", summary="Get recent analytics events for authenticated user")
def get_user_events(limit: int = 50, current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    coll = get_collection("analytics_events")
    cursor = coll.find({"userId": user_id}).sort("createdAt", -1).limit(min(limit, 100))
    events = []
    for it in cursor:
        it["_id"] = str(it["_id"])
        if isinstance(it.get("properties"), str):
            try:
                it["properties"] = json.loads(it["properties"])
            except Exception:
                pass
        events.append(it)
    return events
