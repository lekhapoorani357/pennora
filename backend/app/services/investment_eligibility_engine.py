"""Deterministic Investment Eligibility & Ranking Engine for Pennora.

Evaluates user financial state (income, surplus, emergency coverage, goals, risk profile)
and deterministically filters and ranks candidate investment products.
Uses transparent arithmetic scoring — NEVER asks an LLM to decide suitability.
"""

from __future__ import annotations

import logging
import math
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

logger = logging.getLogger("pennora.investment.eligibility")


class InvestmentEligibilityEngine:
    """Evaluates candidate investment products against user financial reality."""

    @staticmethod
    def evaluate_and_rank_options(
        financial_profile: Optional[Dict[str, Any]],
        goals: Optional[List[Dict[str, Any]]],
        candidate_products: List[Dict[str, Any]],
        recent_transactions: Optional[List[Dict[str, Any]]] = None,
        max_options: int = 6,
    ) -> Dict[str, Any]:
        """Runs deterministic eligibility filtering and ranking.

        Returns structured matching options with explicit reasons and limitations.
        """
        now = datetime.now(timezone.utc)

        # 1. Parse Financial State
        income = 0.0
        fixed_exp = 0.0
        var_exp = 0.0
        emi = 0.0
        current_savings = 0.0
        risk_pref = "Moderate"

        if financial_profile:
            income = float(financial_profile.get("monthlyIncome", 0.0)) + float(
                financial_profile.get("additionalIncome", 0.0)
            )
            fixed_exp = float(financial_profile.get("fixedExpenses", 0.0))
            var_exp = float(financial_profile.get("variableExpenses", 0.0))
            emi = float(financial_profile.get("monthlyEMI", 0.0))
            current_savings = float(financial_profile.get("currentSavings", 0.0))
            risk_pref = str(financial_profile.get("riskTolerance") or financial_profile.get("riskPreference") or "Moderate")

        total_expenses = fixed_exp + var_exp + emi
        monthly_surplus = max(0.0, income - total_expenses)
        essential_expenses = fixed_exp + (0.5 * var_exp) + emi
        emergency_months = (
            (current_savings / essential_expenses)
            if essential_expenses > 0
            else (6.0 if current_savings > 0 else 0.0)
        )

        # 2. Parse Goal Timelines
        min_horizon_months = 36  # Default medium-term horizon if no goals
        active_goals_count = 0
        total_goal_shortfall = 0.0

        if goals:
            for g in goals:
                active_goals_count += 1
                target_amt = float(g.get("targetAmount", 0.0))
                curr_amt = float(g.get("currentAmount", 0.0))
                total_goal_shortfall += max(0.0, target_amt - curr_amt)

                target_date_raw = g.get("targetDate")
                if target_date_raw:
                    try:
                        if isinstance(target_date_raw, str):
                            t_dt = datetime.fromisoformat(target_date_raw.replace("Z", "+00:00"))
                        else:
                            t_dt = target_date_raw
                        if t_dt.tzinfo is None:
                            t_dt = t_dt.replace(tzinfo=timezone.utc)
                        months_rem = max(1, int((t_dt - now).days / 30.4375))
                        if months_rem < min_horizon_months:
                            min_horizon_months = months_rem
                    except Exception:
                        pass

        # 3. Deterministic Filtering & Scoring for Each Product
        scored_products = []

        for p in candidate_products:
            prod_id = str(p.get("id") or p.get("_id") or "")
            name = str(p.get("name") or p.get("product_name") or "Investment Option")
            category = str(p.get("category") or p.get("product_type") or "FD").upper()
            provider = str(p.get("provider") or "Regulated Institution")
            risk = str(p.get("risk") or p.get("risk_level") or "Moderate")
            liquidity = str(p.get("liquidity") or "Moderate")
            min_amount = float(p.get("minAmount") or p.get("minimum_amount") or 500.0)
            rate_or_nav = float(p.get("rate_or_nav") or p.get("assumedAnnualRateMax") or 7.0)
            min_tenure = int(p.get("minTenureMonths") or 6)
            source_name = str(p.get("source_name") or p.get("source") or "Official Provider")
            as_of_date = str(p.get("as_of_date") or now.strftime("%d-%b-%Y"))
            is_guaranteed = bool(p.get("isGuaranteed", False))

            is_eligible = True
            ineligibility_reasons = []

            # Rule A: Emergency Reserve Protection
            # If emergency fund is severely depleted (< 2 months), lock-in products are ineligible
            if emergency_months < 2.0 and liquidity.lower() in ("lock-in", "low"):
                is_eligible = False
                ineligibility_reasons.append(
                    f"Emergency reserve is only {emergency_months:.1f} months. Long-term lock-in instruments require preserving liquid emergency funds first."
                )

            # Rule B: Goal Horizon Compatibility
            if min_horizon_months < 12 and (risk.lower() in ("high", "very high") or min_tenure > 12):
                is_eligible = False
                ineligibility_reasons.append(
                    f"Your nearest goal matures in {min_horizon_months} months. Market volatility or long lock-in does not fit sub-1-year timelines."
                )

            # Rule C: Risk Tolerance Alignment
            if risk_pref.lower() in ("conservative", "low") and risk.lower() in ("high", "very high"):
                is_eligible = False
                ineligibility_reasons.append(
                    f"High-risk instrument does not match your '{risk_pref}' risk tolerance."
                )

            # Rule D: Affordability
            if min_amount > current_savings and min_amount > (monthly_surplus * 3) and current_savings > 0:
                is_eligible = False
                ineligibility_reasons.append(
                    f"Minimum entry (₹{min_amount:,.0f}) exceeds current liquid surplus."
                )

            # Scoring (0 - 100)
            score = 50.0

            # Horizon fit (0-25)
            if min_tenure <= min_horizon_months:
                score += 20.0
            else:
                score -= 15.0

            # Risk fit (0-25)
            if risk_pref.lower() == risk.lower():
                score += 20.0
            elif risk_pref.lower() in ("aggressive", "high"):
                score += 15.0
            elif is_guaranteed:
                score += 18.0

            # Liquidity bonus (0-20)
            if emergency_months < 4.0 and liquidity.lower() == "high":
                score += 15.0
            elif emergency_months >= 4.0 and is_guaranteed:
                score += 10.0

            # Yield quality (0-15)
            if rate_or_nav > 9.0:
                score += 12.0
            elif rate_or_nav >= 6.5:
                score += 8.0

            # Construct transparent reasons
            why_it_matches = (
                f"Suitable for your {min_horizon_months}-month goal timeline. "
                f"{'Offers sovereign/guaranteed capital protection.' if is_guaranteed else 'Provides exposure to long-term wealth compounding.'} "
                f"Requires a low barrier of ₹{min_amount:,.0f} and supports your monthly surplus of ₹{monthly_surplus:,.0f}."
            )

            limitations = []
            if not is_guaranteed:
                limitations.append("Subject to market volatility; capital is not guaranteed.")
            if liquidity.lower() in ("lock-in", "low"):
                limitations.append(f"Funds committed for up to {min_tenure} months with exit restrictions.")
            if p.get("taxNotes"):
                limitations.append(str(p.get("taxNotes")))
            else:
                limitations.append("Standard income tax slabs or capital gains apply upon redemption.")

            risks_and_limitations = " ".join(limitations)

            scored_products.append({
                "product_id": prod_id,
                "product_name": name,
                "category": category,
                "provider": provider,
                "current_rate_or_nav": rate_or_nav,
                "rate_or_nav_text": f"{rate_or_nav:.2f}% p.a." if is_guaranteed or category in ("FD", "RD", "PPF", "GOV_SECURITIES") else f"₹{rate_or_nav:.2f} NAV",
                "risk_level": risk,
                "liquidity": liquidity,
                "minimum_investment": min_amount,
                "source": source_name,
                "as_of_date": as_of_date,
                "is_guaranteed": is_guaranteed,
                "is_eligible": is_eligible,
                "ineligibility_reasons": ineligibility_reasons,
                "why_it_matches": why_it_matches,
                "risks_and_limitations": risks_and_limitations,
                "score": round(score, 1),
            })

        # 4. Rank eligible options & ensure category diversity
        eligible = [p for p in scored_products if p["is_eligible"]]
        eligible.sort(key=lambda x: x["score"], reverse=True)

        selected_options = []
        seen_categories = set()

        # First pass: one from each distinct category
        for p in eligible:
            cat = p["category"]
            if cat not in seen_categories:
                selected_options.append(p)
                seen_categories.add(cat)
            if len(selected_options) >= max_options:
                break

        # Second pass: fill remaining slots with highest scoring eligible
        if len(selected_options) < max_options:
            for p in eligible:
                if p not in selected_options:
                    selected_options.append(p)
                if len(selected_options) >= max_options:
                    break

        return {
            "status": "success",
            "evaluated_at": now.isoformat(),
            "user_financial_summary": {
                "monthly_income": income,
                "monthly_expenses": total_expenses,
                "monthly_surplus": monthly_surplus,
                "current_savings": current_savings,
                "emergency_fund_months": round(emergency_months, 1),
                "risk_preference": risk_pref,
                "nearest_goal_horizon_months": min_horizon_months,
                "active_goals_count": active_goals_count,
            },
            "matching_options_count": len(selected_options),
            "matching_options": selected_options,
            "disclaimer": (
                "Matching options generated using transparent deterministic rules based on your current financial state, "
                "goal timeline, and emergency coverage. Sourced from official entities (AMFI, NSE, Ministry of Finance, SBI). "
                "Not financial advice or sponsored product promotion."
            ),
        }
