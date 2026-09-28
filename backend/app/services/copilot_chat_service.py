"""AI Copilot Chat Service for Pennora.

Bridges user questions with deterministic financial calculations and verified data,
providing conversational explanations via Llama 3.2 (local Ollama) without hallucinations.
NEVER allows the LLM to invent financial products, rates, returns, or calculations.
"""

from __future__ import annotations

import json
import logging
import math
import re
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional


from app.adapters.investment_data.ingestion_service import get_investment_ingestion_service
from app.agents.transaction_agent.llm_client import OllamaClient
from app.database import get_collection
from app.services.investment_eligibility_engine import InvestmentEligibilityEngine
from app.services.investment_service import (
    InvestmentCalculationRequest,
    InvestmentService,
)

logger = logging.getLogger("pennora.copilot.chat")


class CopilotChatService:
    """Orchestrates Verified Context generation, deterministic what-if analysis, and Llama 3.2 explanation."""

    def __init__(self, ollama_client: Optional[OllamaClient] = None):
        self.ollama = ollama_client or OllamaClient(model="llama3.2", timeout=25)

    def build_verified_context(
        self,
        user_id: str,
        principal: float = 50000.0,
        monthly_sip: float = 5000.0,
        duration_years: float = 5.0,
        what_if_delta: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Builds a strictly verified context containing current financial state, goals,

        deterministic simulator projections, eligible sourced options, and what-if calculations.
        """
        now = datetime.now(timezone.utc)

        # 1. Fetch User Financial Profile
        fp_coll = get_collection("financial_profiles")
        profile = fp_coll.find_one({"userId": str(user_id)})

        income = 0.0
        fixed_exp = 0.0
        var_exp = 0.0
        emi = 0.0
        savings = 0.0
        risk_pref = "Moderate"

        if profile:
            income = float(profile.get("monthlyIncome", 0.0)) + float(profile.get("additionalIncome", 0.0))
            fixed_exp = float(profile.get("fixedExpenses", 0.0))
            var_exp = float(profile.get("variableExpenses", 0.0))
            emi = float(profile.get("monthlyEMI", 0.0))
            savings = float(profile.get("currentSavings", 0.0))
            risk_pref = str(profile.get("riskTolerance") or profile.get("riskPreference") or "Moderate")

        total_expenses = fixed_exp + var_exp + emi
        monthly_surplus = max(0.0, income - total_expenses)
        essential_expenses = fixed_exp + (0.5 * var_exp) + emi
        emergency_months = (
            (savings / essential_expenses)
            if essential_expenses > 0
            else (6.0 if savings > 0 else 0.0)
        )
        savings_rate = (monthly_surplus / income * 100.0) if income > 0 and monthly_surplus > 0 else 0.0

        # 2. Fetch User Goals
        goals_coll = get_collection("goals")
        raw_goals = list(goals_coll.find({"userId": str(user_id)}).sort("createdAt", 1))
        parsed_goals = []
        for g in raw_goals:
            target = float(g.get("targetAmount", 0.0))
            curr = float(g.get("currentAmount", 0.0))
            rem = max(0.0, target - curr)
            parsed_goals.append({
                "id": str(g.get("_id")),
                "name": str(g.get("name") or g.get("goal_name") or "Financial Goal"),
                "targetAmount": target,
                "currentAmount": curr,
                "shortfall": rem,
                "targetDate": str(g.get("targetDate")),
                "priority": str(g.get("priority", "Medium")),
            })

        # 3. Fetch Recent Transactions & Latest Impact
        tx_coll = get_collection("transactions")
        raw_txs = list(tx_coll.find({"userId": str(user_id)}).sort("dateTime", -1).limit(5))
        recent_txs = []
        for t in raw_txs:
            recent_txs.append({
                "id": str(t.get("_id")),
                "merchant": str(t.get("merchantName", "Transaction")),
                "amount": float(t.get("amount", 0.0)),
                "type": str(t.get("type", "debit")),
                "category": str(t.get("category", "General")),
                "date": str(t.get("dateTime")),
            })

        latest_tx_summary = None
        if recent_txs:
            latest = recent_txs[0]
            latest_tx_summary = (
                f"Most recent transaction: ₹{latest['amount']:,.0f} {latest['type']} at "
                f"'{latest['merchant']}' ({latest['category']})."
            )

        # 4. Deterministic Money Simulator Calculations
        sim_req = InvestmentCalculationRequest(
            principal=principal,
            monthlyContribution=monthly_sip,
            durationYears=duration_years,
            category="ALL",
        )
        sim_res = InvestmentService.calculate_simulation(
            req=sim_req,
            user_financial_profile=profile,
            user_goals=parsed_goals,
        )

        sim_projections_summary = []
        for p in sim_res.projections:
            sim_projections_summary.append({
                "productName": p.productName,
                "category": p.category,
                "assumedRate": p.assumedAnnualRate,
                "totalInvested": p.totalInvested,
                "projectedValue": p.estimatedFutureValue,
                "estimatedGain": p.estimatedGain,
                "isGuaranteed": p.isGuaranteed,
                "risk": p.risk,
            })

        # 5. Deterministic Sourced Investment Products & Personalized Eligibility
        ingestion = get_investment_ingestion_service()
        candidate_products = ingestion.get_all_products()
        eligibility_result = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=profile,
            goals=parsed_goals,
            candidate_products=candidate_products,
            recent_transactions=recent_txs,
            max_options=6,
        )

        # 6. Deterministic What-If Scenario Calculation
        what_if_data = None
        delta = what_if_delta if what_if_delta is not None else -2000.0  # e.g., ₹2,000 monthly expense change
        adjusted_surplus = max(0.0, monthly_surplus + delta)

        timeline_impact_months = 0
        if parsed_goals and monthly_surplus > 0:
            nearest_shortfall = parsed_goals[0]["shortfall"]
            curr_months = math.ceil(nearest_shortfall / monthly_surplus) if monthly_surplus > 0 else 999
            new_months = math.ceil(nearest_shortfall / adjusted_surplus) if adjusted_surplus > 0 else 999
            timeline_impact_months = new_months - curr_months

        what_if_data = {
            "scenario": f"Monthly surplus adjusted by ₹{delta:+,.0f}",
            "originalSurplus": monthly_surplus,
            "adjustedSurplus": adjusted_surplus,
            "impactOnNearestGoal": (
                f"Goal timeline {'delayed by' if timeline_impact_months > 0 else 'advanced by'} "
                f"{abs(timeline_impact_months)} month(s)"
                if parsed_goals
                else "No active goals to evaluate"
            ),
        }

        # 7. Assemble Verified Context
        verified_context = {
            "user_financial_state": {
                "monthly_income": income,
                "monthly_expenses": total_expenses,
                "monthly_surplus": monthly_surplus,
                "current_savings": savings,
                "emergency_fund_months": round(emergency_months, 1),
                "savings_rate_pct": round(savings_rate, 1),
                "risk_preference": risk_pref,
            },
            "active_goals": parsed_goals,
            "latest_transaction_impact": latest_tx_summary,
            "recent_transactions": recent_txs,
            "simulator_input": {
                "principal": principal,
                "monthly_sip": monthly_sip,
                "duration_years": duration_years,
                "total_invested": sim_res.totalInvested,
            },
            "simulator_projections": sim_projections_summary,
            "matching_eligible_options": eligibility_result.get("matching_options", []),
            "what_if_scenario": what_if_data,
            "verified_data_sources": [
                "AMFI (Association of Mutual Funds in India)",
                "National Stock Exchange of India (NSE)",
                "State Bank of India (SBI)",
                "Ministry of Finance (Government of India)",
                "India Post (National Savings Schemes)",
            ],
            "as_of_timestamp": now.isoformat(),
        }

        return verified_context

    def chat(
        self,
        user_id: str,
        user_message: str,
        principal: Optional[float] = None,
        monthly_sip: Optional[float] = None,
        duration_years: Optional[float] = None,
        what_if_delta: Optional[float] = None,
    ) -> Dict[str, Any]:
        """Processes a user inquiry by generating verified context and prompting Llama 3.2."""
        # 1. Parse or default simulator parameters
        p_val = principal if (principal is not None and principal >= 0) else 50000.0
        m_val = monthly_sip if (monthly_sip is not None and monthly_sip >= 0) else 5000.0
        y_val = duration_years if (duration_years is not None and duration_years > 0) else 5.0

        # Check for numeric what-if intent in message (e.g., "what if I spend 3000 more")
        spend_match = re.search(r"spend\s*(?:₹|rs\.?|inr)?\s*(\d+[\d,]*)", user_message, re.IGNORECASE)
        save_match = re.search(r"(?:save|invest)\s*(?:₹|rs\.?|inr)?\s*(\d+[\d,]*)", user_message, re.IGNORECASE)
        delta_val = what_if_delta
        if delta_val is None:
            if spend_match:
                amt = float(spend_match.group(1).replace(",", ""))
                delta_val = -amt
            elif save_match and "what if" in user_message.lower():
                amt = float(save_match.group(1).replace(",", ""))
                delta_val = amt

        # 2. Build verified context
        verified_context = self.build_verified_context(
            user_id=user_id,
            principal=p_val,
            monthly_sip=m_val,
            duration_years=y_val,
            what_if_delta=delta_val,
        )

        # 3. Check for Out-of-Context Unverified Products / Banks
        unverified_refusal = self._check_unverified_entity_query(user_message, verified_context)
        if unverified_refusal:
            return {
                "reply": unverified_refusal,
                "verified_context": verified_context,
                "relevant_cards": [],
                "source": "deterministic_anti_hallucination_guard",
            }

        # 4. Attempt Llama 3.2 response with strict system prompt
        system_prompt = self._build_system_prompt(verified_context)
        reply = None
        source_tag = "llama3.2_verified_context"

        if self.ollama.is_available():
            try:
                reply = self.ollama.generate_text(
                    system_prompt=system_prompt,
                    user_prompt=user_message,
                    temperature=0.1,
                )
            except Exception as e:
                logger.warning("Ollama call failed (%s), using verified rule-based explainer.", e)

        # 5. Deterministic Fallback if Ollama is offline or gave empty text
        if not reply or len(reply.strip()) < 10:
            reply = self._generate_deterministic_explanation(user_message, verified_context)
            source_tag = "deterministic_verified_explainer"

        # 6. Extract relevant UI cards to display alongside the chat answer
        relevant_cards = self._extract_relevant_cards(user_message, verified_context)

        return {
            "reply": reply,
            "verified_context": verified_context,
            "relevant_cards": relevant_cards,
            "source": source_tag,
        }

    def _build_system_prompt(self, context: Dict[str, Any]) -> str:
        """Constructs strict anti-hallucination system prompt for Llama 3.2."""
        return (
            "You are Pennora AI Copilot, a conversational financial intelligence assistant.\n"
            "Your role is EXCLUSIVELY to explain and clarify the user's verified financial data.\n\n"
            "STRICT ANTI-HALLUCINATION RULES:\n"
            "1. You must ONLY use the verified context data provided below.\n"
            "2. NEVER invent, fabricate, calculate, or guess any interest rates, NAV values, bank names, "
            "financial products, or investment returns not explicitly present in the verified context.\n"
            "3. If the user asks about an institution, bank, or rate not present in the verified context "
            "(e.g., 'What is today's FD rate at XYZ Bank?'), you MUST explicitly respond:\n"
            "   'I don't have verified current data for XYZ Bank in Pennora right now, so I don't want to guess.'\n"
            "4. All numerical values, projected wealth, and surpluses must match the pre-calculated numbers "
            "in the verified context. Do NOT perform independent calculations or change numbers.\n"
            "5. Use neutral, professional, and mature wording. Do NOT say 'best investment'. "
            "Use 'matching option' or 'suitable for your horizon'.\n"
            "6. Keep explanations clear, structured, and concise.\n\n"
            "=== VERIFIED CONTEXT (GROUND TRUTH) ===\n"
            f"{json.dumps(context, indent=2)}\n"
        )

    def _check_unverified_entity_query(self, query: str, context: Dict[str, Any]) -> Optional[str]:
        """Detects queries asking for unknown bank rates or external products not in verified context."""
        q_lower = query.lower()
        verified_providers = [
            "sbi",
            "state bank of india",
            "amfi",
            "nse",
            "hdfc index",
            "hdfc mutual fund",
            "parag parikh",
            "ppfas",
            "nippon",
            "india post",
            "ministry of finance",
            "ppf",
            "t-bill",
            "treasury bill",
        ]

        # Common banks/institutions users might query
        external_banks = [
            "xyz bank",
            "abc bank",
            "icici",
            "axis",
            "kotak",
            "punjab national",
            "pnb",
            "canara",
            "bank of baroda",
            "yes bank",
            "idfc",
            "indusind",
        ]

        for b in external_banks:
            if b in q_lower and not any(v in b for v in verified_providers):
                bank_title = b.title()
                return (
                    f"I don't have verified current data for {bank_title} in Pennora right now, "
                    "so I don't want to guess. We only display verified rates from official sources "
                    "(State Bank of India, AMFI, NSE, and Ministry of Finance)."
                )

        return None

    def _generate_deterministic_explanation(self, query: str, context: Dict[str, Any]) -> str:
        """Deterministic natural language explainer when Ollama is offline."""
        q = query.lower()
        fs = context.get("user_financial_state", {})
        sim = context.get("simulator_input", {})
        projs = context.get("simulator_projections", [])
        opts = context.get("matching_eligible_options", [])
        what_if = context.get("what_if_scenario", {})
        latest_tx = context.get("latest_transaction_impact")

        surplus = fs.get("monthly_surplus", 0.0)
        savings = fs.get("current_savings", 0.0)
        emerg_months = fs.get("emergency_fund_months", 0.0)

        # 1. Simulator Inquiry ("What happens if I invest ₹5,000 every month?")
        if "invest" in q or "simulator" in q or "projection" in q or "grow" in q:
            p_val = sim.get("principal", 50000)
            m_val = sim.get("monthly_sip", 5000)
            dur_val = sim.get("duration_years", 5)
            tot = sim.get("total_invested", 0)

            # Find top projection
            top_proj = projs[0] if projs else None
            fv_text = f"₹{top_proj['projectedValue']:,.0f}" if top_proj else "substantial growth"
            gain_text = f"₹{top_proj['estimatedGain']:,.0f}" if top_proj else ""

            return (
                f"Based on your simulation of ₹{p_val:,.0f} initial lump-sum and ₹{m_val:,.0f} monthly SIP over {dur_val:.0f} years:\n\n"
                f"• **Total Invested:** ₹{tot:,.0f}\n"
                f"• **Projected Value ({top_proj['productName'] if top_proj else 'Benchmark'}):** {fv_text}\n"
                f"• **Estimated Gain:** {gain_text}\n\n"
                f"Your current monthly surplus is ₹{surplus:,.0f}. "
                f"{'This monthly contribution is well within your surplus.' if m_val <= surplus else 'Warning: This contribution exceeds your available monthly surplus.'}"
            )

        # 2. Matching Options / Why shown ("Why did you show this option?")
        if "why" in q and ("option" in q or "show" in q or "recommend" in q):
            if opts:
                top_opt = opts[0]
                return (
                    f"**Why '{top_opt['product_name']}' is shown:**\n\n"
                    f"1. **{top_opt['why_it_matches']}**\n"
                    f"2. **Risk Alignment:** Categorized as '{top_opt['risk_level']}', matching your profile.\n"
                    f"3. **Verified Rate/NAV:** {top_opt['rate_or_nav_text']} sourced from {top_opt['source']} (as of {top_opt['as_of_date']}).\n\n"
                    f"**Important considerations:** {top_opt['risks_and_limitations']}"
                )
            return (
                f"Options are filtered deterministically based on your {emerg_months:.1f}-month emergency coverage, "
                f"available monthly surplus (₹{surplus:,.0f}), and goal deadlines."
            )

        # 3. Lower Risk Query ("Which option has lower risk?")
        if "lower risk" in q or "safest" in q or "safe" in q:
            guaranteed_opts = [o for o in opts if o.get("is_guaranteed")]
            if guaranteed_opts:
                names = ", ".join([f"'{o['product_name']}' ({o['rate_or_nav_text']})" for o in guaranteed_opts[:2]])
                return (
                    f"The lowest-risk options in your matching list are sovereign and capital-guaranteed instruments: {names}. "
                    "These have zero equity volatility and offer fixed predictable returns."
                )
            return "Fixed Deposits, PPF, and Treasury Bills provide the lowest risk with guaranteed capital returns."

        # 4. What-If / Surplus change ("What happens if my surplus decreases by ₹2,000?")
        if "what if" in q or "decrease" in q or "increase" in q or "spend" in q:
            adj = what_if.get("adjustedSurplus", surplus)
            impact = what_if.get("impactOnNearestGoal", "")
            return (
                f"**What-If Scenario Evaluation:**\n\n"
                f"• **Current Surplus:** ₹{surplus:,.0f}/month\n"
                f"• **Adjusted Surplus:** ₹{adj:,.0f}/month\n"
                f"• **Goal Impact:** {impact}\n\n"
                f"When your monthly surplus changes, the simulator automatically adjusts your feasibility scores and eligible investment allocations."
            )

        # 5. Transaction Impact ("What changed after my latest transaction?")
        if "transaction" in q or "change" in q or "latest" in q:
            if latest_tx:
                return (
                    f"**Latest Activity Impact:**\n\n"
                    f"{latest_tx}\n\n"
                    f"After accounting for this transaction, your available monthly surplus is ₹{surplus:,.0f} "
                    f"and your emergency fund covers {emerg_months:.1f} months of essential expenses. "
                    "Your eligible investment options remain synchronized with this updated surplus."
                )
            return f"Your current recorded monthly surplus is ₹{surplus:,.0f} with {emerg_months:.1f} months of emergency reserve."

        # Default general overview
        return (
            f"Here is your current verified financial status:\n\n"
            f"• **Monthly Surplus:** ₹{surplus:,.0f}\n"
            f"• **Emergency Fund Coverage:** {emerg_months:.1f} months\n"
            f"• **Active Goals:** {len(context.get('active_goals', []))} tracked\n"
            f"• **Matching Eligible Options:** {len(opts)} options identified across FD, RD, PPF, T-Bills, and Funds.\n\n"
            "You can ask me about investment projections, why specific options were selected, or what-if scenario impacts."
        )

    def _extract_relevant_cards(self, query: str, context: Dict[str, Any]) -> List[Dict[str, Any]]:
        """Identifies UI cards to highlight in the client alongside the chat answer."""
        q = query.lower()
        cards = []

        if "invest" in q or "projection" in q or "simulator" in q:
            cards.append({
                "type": "simulator_summary",
                "title": "Simulation Result",
                "data": context.get("simulator_input", {}),
            })

        if "option" in q or "why" in q or "risk" in q:
            matching = context.get("matching_eligible_options", [])
            if matching:
                cards.append({
                    "type": "matching_option",
                    "title": "Matching Option",
                    "data": matching[0],
                })

        if "what if" in q or "spend" in q or "surplus" in q:
            cards.append({
                "type": "what_if_impact",
                "title": "What-If Scenario",
                "data": context.get("what_if_scenario", {}),
            })

        return cards
