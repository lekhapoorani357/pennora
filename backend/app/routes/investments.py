"""FastAPI Router for Pennora Investment & Money Growth Simulator."""

from __future__ import annotations

import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user, get_optional_current_user
from app.services.investment_service import (
    InvestmentService,
    InvestmentCalculationRequest,
    InvestmentSimulationResponse,
)

router = APIRouter(prefix="/api/investments", tags=["Investment Growth Simulator"])


class SaveScenarioRequest(BaseModel):
    initialAmount: float = Field(..., ge=0.0)
    monthlyContribution: float = Field(0.0, ge=0.0)
    durationYears: float = Field(..., gt=0.0)
    selectedProductIds: Optional[List[str]] = None
    results: Dict[str, Any]


class CopilotChatRequest(BaseModel):
    message: str = Field(..., min_length=1)
    principal: Optional[float] = Field(None, ge=0.0)
    monthlyContribution: Optional[float] = Field(None, ge=0.0)
    durationYears: Optional[float] = Field(None, gt=0.0)
    whatIfMonthlyDelta: Optional[float] = None
    selectedProductId: Optional[str] = None


@router.get("/options", summary="Get supported investment and money growth options")
def get_investment_options(category: Optional[str] = None):
    """Returns curated educational investment products and parameters."""
    return {
        "products": InvestmentService.get_products(category),
        "disclaimer": "Sourced official data from AMFI, NSE India, Ministry of Finance, and State Bank of India.",
    }


@router.get("/eligible", summary="Get personalized eligible and ranked investment options")
def get_eligible_investment_options(current_user: dict = Depends(get_optional_current_user)):
    """Deterministically evaluates user financial profile, goals, and transactions to rank eligible options."""
    from app.services.investment_eligibility_engine import InvestmentEligibilityEngine
    from app.adapters.investment_data.ingestion_service import get_investment_ingestion_service

    user_id = str(current_user["_id"])
    fin_coll = get_collection("financial_profiles")
    user_profile = fin_coll.find_one({"userId": user_id})

    goals_coll = get_collection("goals")
    user_goals = list(goals_coll.find({"userId": user_id}))

    tx_coll = get_collection("transactions")
    recent_txs = list(tx_coll.find({"userId": user_id}).sort("dateTime", -1).limit(5))

    candidate_products = get_investment_ingestion_service().get_all_products()

    return InvestmentEligibilityEngine.evaluate_and_rank_options(
        financial_profile=user_profile,
        goals=user_goals,
        candidate_products=candidate_products,
        recent_transactions=recent_txs,
        max_options=6,
    )


@router.post("/copilot/chat", summary="Chat with AI Copilot using strictly verified financial context")
def copilot_chat(
    payload: CopilotChatRequest,
    current_user: dict = Depends(get_optional_current_user),
):
    """Processes financial questions via Llama 3.2 using pre-calculated deterministic context without hallucinations."""
    from app.services.copilot_chat_service import CopilotChatService

    user_id = str(current_user["_id"])
    service = CopilotChatService()

    return service.chat(
        user_id=user_id,
        user_message=payload.message,
        principal=payload.principal,
        monthly_sip=payload.monthlyContribution,
        duration_years=payload.durationYears,
        what_if_delta=payload.whatIfMonthlyDelta,
    )



@router.post("/sync-sourced", summary="Trigger synchronization with official market data adapters")
def sync_sourced_investments(current_user: dict = Depends(get_current_user)):
    """Synchronizes products from AMFI, NSE, and official government/banking rate sources."""
    from app.adapters.investment_data.ingestion_service import get_investment_ingestion_service

    service = get_investment_ingestion_service()
    res = service.sync_all_adapters()
    return res



@router.post(
    "/calculate",
    response_model=InvestmentSimulationResponse,
    summary="Deterministic projection and goal impact calculation",
)
def calculate_simulation(
    payload: InvestmentCalculationRequest,
    current_user: dict = Depends(get_current_user),
):
    """Calculates deterministic future values, ranges, and evaluates upcoming goal impacts."""
    user_id = str(current_user["_id"])

    # Fetch user financial profile and goals
    fin_coll = get_collection("financial_profiles")
    user_profile = fin_coll.find_one({"userId": user_id})

    goals_coll = get_collection("goals")
    user_goals = list(goals_coll.find({"userId": user_id}))

    return InvestmentService.calculate_simulation(
        req=payload,
        user_financial_profile=user_profile,
        user_goals=user_goals,
    )


@router.post("/scenarios", status_code=status.HTTP_201_CREATED, summary="Save investment scenario")
def save_scenario(
    payload: SaveScenarioRequest,
    current_user: dict = Depends(get_current_user),
):
    """Persists an investment simulation for user review."""
    user_id = str(current_user["_id"])
    coll = get_collection("investment_scenarios")
    now = datetime.now(timezone.utc)

    doc = {
        "userId": user_id,
        "initialAmount": payload.initialAmount,
        "monthlyContribution": payload.monthlyContribution,
        "tenureMonths": int(payload.durationYears * 12),
        "selectedProductIds": json.dumps(payload.selectedProductIds or []),
        "results": json.dumps(payload.results),
        "createdAt": now,
    }
    res = coll.insert_one(doc)

    # Track analytics event
    try:
        analytics_coll = get_collection("analytics_events")
        analytics_coll.insert_one({
            "userId": user_id,
            "eventName": "scenario_created",
            "properties": json.dumps({"type": "investment_scenario", "principal": payload.initialAmount}),
            "isDemo": False,
            "createdAt": now,
        })
    except Exception:
        pass

    return {
        "id": str(res.inserted_id),
        "status": "saved",
        "message": "Investment scenario saved successfully.",
    }


@router.get("/scenarios", summary="Get user's saved investment scenarios")
def get_user_scenarios(current_user: dict = Depends(get_current_user)):
    user_id = str(current_user["_id"])
    coll = get_collection("investment_scenarios")
    items = list(coll.find({"userId": user_id}).sort("createdAt", -1))
    for it in items:
        it["_id"] = str(it["_id"])
        if isinstance(it.get("results"), str):
            try:
                it["results"] = json.loads(it["results"])
            except Exception:
                pass
    return items
