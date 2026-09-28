"""Deterministic Investment and Money Growth Simulator Service for Pennora.

Provides deterministic mathematical models for lump-sum and recurring investments,
incorporating user financial state and active goals to evaluate liquidity and goal impacts.
NEVER uses LLMs for financial arithmetic.
"""

from __future__ import annotations

import math
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional
from pydantic import BaseModel, Field

# Seed investment product database
DEFAULT_INVESTMENT_PRODUCTS = [
    {
        "id": "prod_fd_1",
        "name": "Fixed Deposit (FD)",
        "category": "FD",
        "description": "Safe fixed-income deposit with guaranteed returns and flexible tenure.",
        "minTenureMonths": 6,
        "maxTenureMonths": 120,
        "minAmount": 1000.0,
        "assumedAnnualRateMin": 6.5,
        "assumedAnnualRateMax": 7.5,
        "defaultRate": 7.0,
        "risk": "Low",
        "liquidity": "Moderate",
        "taxNotes": "Interest is taxable as per your income tax slab. TDS applicable above ₹40,000/year.",
        "isGuaranteed": True,
        "source": "Illustrative banking average for demonstration",
        "isDemo": True,
    },
    {
        "id": "prod_rd_1",
        "name": "Recurring Deposit (RD)",
        "category": "RD",
        "description": "Discipline-building monthly recurring deposit with fixed returns.",
        "minTenureMonths": 6,
        "maxTenureMonths": 120,
        "minAmount": 500.0,
        "assumedAnnualRateMin": 6.2,
        "assumedAnnualRateMax": 7.2,
        "defaultRate": 6.8,
        "risk": "Low",
        "liquidity": "Moderate",
        "taxNotes": "Interest taxable as per income slab.",
        "isGuaranteed": True,
        "source": "Illustrative banking average for demonstration",
        "isDemo": True,
    },
    {
        "id": "prod_ppf_1",
        "name": "Public Provident Fund (PPF)",
        "category": "PPF",
        "description": "Government-backed long-term savings with tax-free returns and capital safety.",
        "minTenureMonths": 60,
        "maxTenureMonths": 180,
        "minAmount": 500.0,
        "assumedAnnualRateMin": 7.1,
        "assumedAnnualRateMax": 7.1,
        "defaultRate": 7.1,
        "risk": "Low",
        "liquidity": "Lock-in",
        "taxNotes": "Exempt-Exempt-Exempt (EEE) category: Principal, interest, and maturity are tax-free under Sec 80C.",
        "isGuaranteed": True,
        "source": "Government of India notified rate (Illustrative demonstration)",
        "isDemo": True,
    },
    {
        "id": "prod_index_1",
        "name": "Nifty 50 Index Mutual Fund",
        "category": "INDEX_FUNDS",
        "description": "Low-cost index fund tracking India's top 50 blue-chip companies.",
        "minTenureMonths": 12,
        "maxTenureMonths": 240,
        "minAmount": 500.0,
        "assumedAnnualRateMin": 9.0,
        "assumedAnnualRateMax": 14.0,
        "defaultRate": 11.5,
        "risk": "Moderate",
        "liquidity": "High",
        "taxNotes": "Long term capital gains (held > 1 yr) taxed at 12.5% above ₹1.25 Lakh exemption. Short term taxed at 20%.",
        "isGuaranteed": False,
        "source": "Historical broad-market benchmark illustrative range",
        "isDemo": True,
    },
    {
        "id": "prod_equity_1",
        "name": "Diversified Equity / Mutual Funds",
        "category": "EQUITY",
        "description": "Actively managed equity funds focused on wealth compounding across market sectors.",
        "minTenureMonths": 24,
        "maxTenureMonths": 240,
        "minAmount": 500.0,
        "assumedAnnualRateMin": 10.0,
        "assumedAnnualRateMax": 16.0,
        "defaultRate": 12.5,
        "risk": "High",
        "liquidity": "High",
        "taxNotes": "Equity taxation applies (12.5% LTCG > ₹1.25L, 20% STCG).",
        "isGuaranteed": False,
        "source": "Category historical illustrative projection",
        "isDemo": True,
    },
]


def calculate_lump_sum(principal: float, annual_rate_pct: float, years: float) -> float:
    """Calculates FV = P * (1 + r)^t deterministically."""
    if principal <= 0 or years <= 0:
        return max(0.0, principal)
    r = annual_rate_pct / 100.0
    return principal * math.pow(1.0 + r, years)


def calculate_sip(monthly_amount: float, annual_rate_pct: float, months: int) -> float:
    """Calculates FV for monthly contributions: FV = P * [((1 + i)^n - 1) / i] * (1 + i)."""
    if monthly_amount <= 0 or months <= 0:
        return 0.0
    if annual_rate_pct <= 0:
        return monthly_amount * months

    monthly_rate = (annual_rate_pct / 100.0) / 12.0
    fv = monthly_amount * ((math.pow(1.0 + monthly_rate, months) - 1.0) / monthly_rate) * (1.0 + monthly_rate)
    return fv


class InvestmentCalculationRequest(BaseModel):
    principal: float = Field(..., ge=0.0)
    monthlyContribution: float = Field(0.0, ge=0.0)
    durationYears: float = Field(..., gt=0.0, le=40.0)
    category: Optional[str] = None  # FD, RD, PPF, INDEX_FUNDS, EQUITY or all
    customAnnualRate: Optional[float] = Field(None, ge=0.0, le=100.0)


class ProductProjection(BaseModel):
    productId: str
    productName: str
    category: str
    isGuaranteed: bool
    risk: str
    liquidity: str
    assumedAnnualRate: float
    rateRangeText: str
    totalInvested: float
    estimatedFutureValue: float
    estimatedGain: float
    conservativeValue: Optional[float] = None
    optimisticValue: Optional[float] = None
    taxNotes: Optional[str] = None
    disclaimer: str
    source: str


class GoalImpactEvaluation(BaseModel):
    canAffordLumpSum: bool
    surplusLiquidAfterInvestment: float
    emergencyFundCoveredMonths: float
    hasLiquidityWarning: bool
    warnings: List[str]
    affectedUpcomingGoals: List[Dict[str, Any]]
    suggestedAllocation: Dict[str, Any]


class InvestmentSimulationResponse(BaseModel):
    principal: float
    monthlyContribution: float
    durationYears: float
    totalInvested: float
    projections: List[ProductProjection]
    goalImpact: GoalImpactEvaluation
    disclaimer: str


class InvestmentService:
    @staticmethod
    def get_products(category: Optional[str] = None) -> List[Dict[str, Any]]:
        try:
            from app.adapters.investment_data.ingestion_service import get_investment_ingestion_service
            prods = get_investment_ingestion_service().get_all_products(category)
            if prods:
                return prods
        except Exception:
            pass

        if not category or category.upper() == "ALL":
            return DEFAULT_INVESTMENT_PRODUCTS
        cat = category.strip().upper()
        return [p for p in DEFAULT_INVESTMENT_PRODUCTS if p["category"] == cat]

    @staticmethod
    def calculate_simulation(
        req: InvestmentCalculationRequest,
        user_financial_profile: Optional[Dict[str, Any]] = None,
        user_goals: Optional[List[Dict[str, Any]]] = None,
    ) -> InvestmentSimulationResponse:
        principal = float(req.principal)
        monthly = float(req.monthlyContribution)
        years = float(req.durationYears)
        months = int(round(years * 12))
        total_invested = principal + (monthly * months)

        products = InvestmentService.get_products(req.category)
        projections: List[ProductProjection] = []

        disclaimer_text = (
            "Illustrative projected value based on the selected assumptions. "
            "Actual returns may differ. Not guaranteed financial advice."
        )

        for prod in products:
            annual_max = float(prod.get("assumedAnnualRateMax") or 7.0)
            def_rate = float(prod.get("defaultRate") or annual_max)
            if def_rate > 35.0:
                def_rate = annual_max if annual_max <= 35.0 else 7.0
            rate = (
                req.customAnnualRate
                if req.customAnnualRate is not None
                else def_rate
            )
            rate_min = float(prod.get("assumedAnnualRateMin", 6.0))

            rate_max = float(prod.get("assumedAnnualRateMax", 8.0))
            is_guar = bool(prod.get("isGuaranteed", False))

            # Expected projection
            fv_lump = calculate_lump_sum(principal, rate, years)
            fv_sip = calculate_sip(monthly, rate, months)
            fv_total = fv_lump + fv_sip
            gain = max(0.0, fv_total - total_invested)

            # Ranges for market-linked products
            conservative_val = None
            optimistic_val = None
            if not is_guar:
                c_lump = calculate_lump_sum(principal, rate_min, years)
                c_sip = calculate_sip(monthly, rate_min, months)
                conservative_val = round(c_lump + c_sip, 2)

                o_lump = calculate_lump_sum(principal, rate_max, years)
                o_sip = calculate_sip(monthly, rate_max, months)
                optimistic_val = round(o_lump + o_sip, 2)

            rate_range = (
                f"{rate:.1f}%"
                if rate_min == rate_max
                else f"{rate_min:.1f}% – {rate_max:.1f}%"
            )

            projections.append(
                ProductProjection(
                    productId=str(prod.get("id") or prod.get("_id") or ""),
                    productName=str(prod.get("name") or prod.get("product_name") or "Investment"),
                    category=str(prod.get("category") or prod.get("product_type") or "FD"),
                    isGuaranteed=is_guar,
                    risk=str(prod.get("risk") or prod.get("risk_level") or "Moderate"),
                    liquidity=str(prod.get("liquidity") or "Moderate"),
                    assumedAnnualRate=round(rate, 2),
                    rateRangeText=rate_range,
                    totalInvested=round(total_invested, 2),
                    estimatedFutureValue=round(fv_total, 2),
                    estimatedGain=round(gain, 2),
                    conservativeValue=conservative_val,
                    optimisticValue=optimistic_val,
                    taxNotes=prod.get("taxNotes"),
                    disclaimer=disclaimer_text,
                    source=str(prod.get("source_name") or prod.get("source") or "Official Sourced Entity"),
                )
            )


        # -------------------------------------------------------------
        # Part 12: Goal Impact Evaluation Before Investment
        # -------------------------------------------------------------
        warnings: List[str] = []
        affected_goals: List[Dict[str, Any]] = []

        curr_savings = 0.0
        fixed_exp = 0.0
        var_exp = 0.0
        monthly_income = 0.0

        if user_financial_profile:
            curr_savings = float(user_financial_profile.get("currentSavings", 0.0))
            fixed_exp = float(user_financial_profile.get("fixedExpenses", 0.0))
            var_exp = float(user_financial_profile.get("variableExpenses", 0.0))
            monthly_income = float(user_financial_profile.get("monthlyIncome", 0.0))

        essential_monthly_expenses = fixed_exp + (var_exp * 0.5)
        remaining_savings_after_lump = max(0.0, curr_savings - principal)

        emergency_months = (
            (remaining_savings_after_lump / essential_monthly_expenses)
            if essential_monthly_expenses > 0
            else 6.0
        )

        has_liquidity_warning = False

        if principal > curr_savings and curr_savings > 0:
            warnings.append(
                f"Lump-sum (₹{principal:,.0f}) exceeds your current recorded savings (₹{curr_savings:,.0f})."
            )
            has_liquidity_warning = True

        if emergency_months < 3.0 and essential_monthly_expenses > 0:
            warnings.append(
                f"After committing ₹{principal:,.0f}, emergency coverage drops to {emergency_months:.1f} months. (Recommended: 3–6 months essential expenses)."
            )
            has_liquidity_warning = True

        # Check goals with target date within investment horizon
        if user_goals:
            now_dt = datetime.now(timezone.utc)
            for g in user_goals:
                target_date_str = g.get("targetDate")
                target_amt = float(g.get("targetAmount", 0.0))
                current_amt = float(g.get("currentAmount", 0.0))
                shortfall = max(0.0, target_amt - current_amt)

                months_to_goal = 12
                if target_date_str:
                    try:
                        td = datetime.fromisoformat(str(target_date_str).replace("Z", "+00:00"))
                        months_to_goal = max(1, int((td - now_dt).days / 30.4))
                    except Exception:
                        months_to_goal = 12

                # If goal deadline is sooner than investment tenure
                if months_to_goal <= months:
                    affected_goals.append({
                        "goalName": g.get("name") or g.get("goal_name", "Goal"),
                        "targetAmount": target_amt,
                        "currentAmount": current_amt,
                        "shortfall": shortfall,
                        "monthsRemaining": months_to_goal,
                        "priority": g.get("priority", "Medium"),
                        "impactNotice": (
                            f"Target date is in {months_to_goal} months (within {years:.1f}y investment horizon). "
                            "Locking funds in long-term instruments may restrict liquidity for this goal."
                        ),
                    })

        if affected_goals:
            warnings.append(
                f"Found {len(affected_goals)} active goal(s) maturing within your chosen {years:.1f}-year horizon. Consider keeping adequate liquidity."
            )

        # Scenarios A, B, C breakdown
        suggested_allocation = {
            "scenarioA_liquid": {
                "name": "Scenario A — Liquid Safety",
                "recommendedAmount": round(min(principal, essential_monthly_expenses * 3), 2),
                "strategy": "Keep in high-yield savings or liquid account for emergency buffer & upcoming goals.",
            },
            "scenarioB_fixedIncome": {
                "name": "Scenario B — Capital Preservation (FD/RD/PPF)",
                "recommendedAmount": round(principal * 0.6, 2),
                "strategy": "Guaranteed capital returns with low risk for predictable timelines.",
            },
            "scenarioC_marketLinked": {
                "name": "Scenario C — Growth Oriented (Index Funds/Equity)",
                "recommendedAmount": round(principal * 0.4, 2),
                "strategy": "Long-term compounding with market exposure. Best suited for horizons > 3–5 years.",
            },
        }

        goal_impact = GoalImpactEvaluation(
            canAffordLumpSum=(principal <= curr_savings or curr_savings == 0),
            surplusLiquidAfterInvestment=round(remaining_savings_after_lump, 2),
            emergencyFundCoveredMonths=round(emergency_months, 1),
            hasLiquidityWarning=has_liquidity_warning,
            warnings=warnings,
            affectedUpcomingGoals=affected_goals,
            suggestedAllocation=suggested_allocation,
        )

        return InvestmentSimulationResponse(
            principal=principal,
            monthlyContribution=monthly,
            durationYears=years,
            totalInvested=round(total_invested, 2),
            projections=projections,
            goalImpact=goal_impact,
            disclaimer=disclaimer_text,
        )
