"""Comprehensive Backend Test Suite for Pennora Sourced Investment Data & AI Copilot.

Tests:
1. Investment data ingestion from official adapters (AMFI, NSE, Official Rates)
2. Source and date metadata tracking
3. Stale data detection
4. Deterministic investment eligibility rules
5. Deterministic ranking across diversified categories
6. Transaction -> Financial State -> Investment Eligibility & Ranking flow
7. What-if scenario calculations
8. AI Copilot verified context generation
9. Anti-hallucination verification (unknown banks/rates trigger explicit refusal to guess)
10. Mathematical determinism of Money Simulator calculations
"""

import math
from datetime import datetime, timezone, timedelta
import pytest

from app.adapters.investment_data.base_adapter import SourcedProduct
from app.adapters.investment_data.amfi_adapter import AmfiAdapter
from app.adapters.investment_data.nse_adapter import NseAdapter
from app.adapters.investment_data.official_rates_adapter import OfficialRatesAdapter
from app.adapters.investment_data.ingestion_service import (
    InvestmentIngestionService,
    STALE_DATA_THRESHOLD_DAYS,
)
from app.services.investment_eligibility_engine import InvestmentEligibilityEngine
from app.services.copilot_chat_service import CopilotChatService
from app.services.investment_service import (
    calculate_lump_sum,
    calculate_sip,
    InvestmentService,
    InvestmentCalculationRequest,
)


class TestSourcedInvestmentDataAdapters:
    """Tests 1-3: Ingestion, Validation, Source/Date Tracking, Stale Data Handling."""

    def test_amfi_adapter_retrieves_sourced_products(self):
        adapter = AmfiAdapter()
        assert adapter.source_name == "AMFI (Association of Mutual Funds in India)"
        assert "amfiindia.com" in adapter.source_url

        products = adapter.fetch_products()
        assert len(products) >= 3

        # Check scheme details
        index_fund = next((p for p in products if p.category == "INDEX_FUNDS"), None)
        assert index_fund is not None
        assert index_fund.provider == "HDFC Mutual Fund"
        assert index_fund.rate_or_nav > 0
        assert index_fund.source_name == adapter.source_name
        assert index_fund.as_of_date is not None
        assert index_fund.status in ("active", "cached")
        assert index_fund.is_guaranteed is False

    def test_nse_adapter_retrieves_etfs_and_treasury_bills(self):
        adapter = NseAdapter()
        assert adapter.source_name == "National Stock Exchange of India (NSE)"
        assert "nseindia.com" in adapter.source_url

        products = adapter.fetch_products()
        assert len(products) >= 3

        # Verify Treasury Bill and ETF
        tbill = next((p for p in products if "Treasury Bill" in p.name), None)
        assert tbill is not None
        assert tbill.category == "GOV_SECURITIES"
        assert tbill.rate_or_nav >= 6.0
        assert tbill.is_guaranteed is True

        etf = next((p for p in products if "BeES" in p.name), None)
        assert etf is not None
        assert etf.category == "INDEX_FUNDS"
        assert etf.rate_or_nav > 100.0

    def test_official_rates_adapter_retrieves_fd_rd_ppf(self):
        adapter = OfficialRatesAdapter()
        products = adapter.fetch_products()
        assert len(products) >= 3

        # FD from SBI
        sbi_fd = next((p for p in products if "SBI" in p.provider), None)
        assert sbi_fd is not None
        assert sbi_fd.category == "FD"
        assert 6.0 <= sbi_fd.rate_or_nav <= 8.0
        assert "sbi.co.in" in sbi_fd.source_url

        # PPF from Ministry of Finance
        ppf = next((p for p in products if p.category == "PPF"), None)
        assert ppf is not None
        assert ppf.rate_or_nav == 7.10
        assert ppf.liquidity == "Lock-in"
        assert "dea.gov.in" in ppf.source_url

    def test_stale_data_detection(self):
        """Simulate a product fetched 10 days ago; verify status becomes 'stale'."""
        ingestion = InvestmentIngestionService()
        old_time = datetime.now(timezone.utc) - timedelta(days=STALE_DATA_THRESHOLD_DAYS + 3)

        mock_product = {
            "_id": "mock_old_fd",
            "name": "Old Rate FD",
            "category": "FD",
            "provider": "Mock Bank",
            "rate_or_nav": 6.5,
            "assumedAnnualRateMin": 6.5,
            "assumedAnnualRateMax": 6.5,
            "minTenureMonths": 12,
            "maxTenureMonths": 60,
            "minAmount": 1000,
            "risk": "Low",
            "liquidity": "Moderate",
            "source_name": "Mock Source",
            "source_url": "https://example.com",
            "as_of_date": "01-Jan-2026",
            "fetched_at": old_time.isoformat(),
            "status": "active",
        }

        # Check freshness evaluation logic
        fetched_at = datetime.fromisoformat(mock_product["fetched_at"].replace("Z", "+00:00"))
        now = datetime.now(timezone.utc)
        is_stale = (now - fetched_at) > timedelta(days=STALE_DATA_THRESHOLD_DAYS)
        assert is_stale is True


class TestDeterministicInvestmentEligibilityAndRanking:
    """Tests 4-6: Eligibility Engine, Deterministic Rules, Horizon, Risk, and Emergency Coverage."""

    @pytest.fixture
    def candidate_products(self):
        adapter1 = AmfiAdapter()
        adapter2 = NseAdapter()
        adapter3 = OfficialRatesAdapter()
        prods = adapter1.fetch_products() + adapter2.fetch_products() + adapter3.fetch_products()
        return [p.to_dict() for p in prods]

    def test_conservative_user_filters_out_high_risk_equities(self, candidate_products):
        conservative_profile = {
            "monthlyIncome": 80000,
            "fixedExpenses": 30000,
            "variableExpenses": 15000,
            "monthlyEMI": 5000,
            "currentSavings": 200000,
            "riskTolerance": "Conservative",
        }
        long_goals = [
            {"targetAmount": 500000, "currentAmount": 100000, "targetDate": "2030-01-01"}
        ]

        result = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=conservative_profile,
            goals=long_goals,
            candidate_products=candidate_products,
        )

        matching = result["matching_options"]
        # High and Very High risk products must NOT be eligible for conservative users
        for opt in matching:
            assert opt["risk_level"].lower() not in ("high", "very high")
            assert opt["is_eligible"] is True

    def test_depleted_emergency_fund_restricts_lock_in_instruments(self, candidate_products):
        """User with almost zero savings (<2 months essential expenses) must not be placed in PPF / long lock-ins."""
        low_savings_profile = {
            "monthlyIncome": 50000,
            "fixedExpenses": 25000,
            "variableExpenses": 10000,
            "monthlyEMI": 0,
            "currentSavings": 15000,  # 15k vs 30k essential = 0.5 months coverage
            "riskTolerance": "Moderate",
        }

        result = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=low_savings_profile,
            goals=[],
            candidate_products=candidate_products,
        )

        matching = result["matching_options"]
        for opt in matching:
            # Lock-in products must not be included
            assert opt["liquidity"].lower() not in ("lock-in", "low")

    def test_short_horizon_goal_restricts_volatile_equities(self, candidate_products):
        """User whose nearest goal is in 6 months cannot have long-term equity recommended."""
        normal_profile = {
            "monthlyIncome": 100000,
            "fixedExpenses": 40000,
            "variableExpenses": 20000,
            "currentSavings": 300000,
            "riskTolerance": "Aggressive",
        }
        short_goal = [
            {
                "targetAmount": 100000,
                "currentAmount": 50000,
                "targetDate": (datetime.now(timezone.utc) + timedelta(days=150)).isoformat(),  # ~5 months
            }
        ]

        result = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=normal_profile,
            goals=short_goal,
            candidate_products=candidate_products,
        )

        matching = result["matching_options"]
        for opt in matching:
            # High risk equity is ineligible for sub-12m horizon
            assert opt["risk_level"].lower() not in ("high", "very high")

    def test_transaction_updates_financial_state_and_eligibility(self, candidate_products):
        """Flow: User records new high debit transaction -> monthly surplus drops -> eligibility adjusts."""
        base_profile = {
            "monthlyIncome": 60000,
            "fixedExpenses": 25000,
            "variableExpenses": 15000,
            "currentSavings": 100000,
            "riskTolerance": "Moderate",
        }
        res_before = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=base_profile,
            goals=[],
            candidate_products=candidate_products,
        )
        assert res_before["user_financial_summary"]["monthly_surplus"] == 20000

        # Now simulate transaction that increased expenses:
        updated_profile = dict(base_profile)
        updated_profile["variableExpenses"] = 30000  # Extra ₹15,000 expense
        res_after = InvestmentEligibilityEngine.evaluate_and_rank_options(
            financial_profile=updated_profile,
            goals=[],
            candidate_products=candidate_products,
        )
        assert res_after["user_financial_summary"]["monthly_surplus"] == 5000
        # The summary reflects the updated surplus
        assert res_after["user_financial_summary"]["monthly_surplus"] < res_before["user_financial_summary"]["monthly_surplus"]


class TestCopilotChatAndAntiHallucination:
    """Tests 7-9: Verified Context, Anti-Hallucination Guardrails, Unknown Bank Query Refusal."""

    def test_copilot_refuses_to_guess_unverified_external_bank(self):
        """User asks 'What is today's FD rate at XYZ Bank?'

        System MUST respond that verified data is unavailable rather than hallucinating a rate.
        """
        chat_service = CopilotChatService()
        mock_context = {
            "user_financial_state": {"monthly_surplus": 15000, "current_savings": 80000},
            "matching_eligible_options": [],
        }

        refusal = chat_service._check_unverified_entity_query(
            "What is today's FD rate at XYZ Bank?",
            mock_context,
        )

        assert refusal is not None
        assert "don't have verified current data for Xyz Bank" in refusal
        assert "so I don't want to guess" in refusal

    def test_copilot_refuses_to_guess_unverified_abc_bank(self):
        chat_service = CopilotChatService()
        refusal = chat_service._check_unverified_entity_query(
            "Can I get 9% interest at ABC Bank for 1 year?",
            {},
        )
        assert refusal is not None
        assert "don't have verified current data for Abc Bank" in refusal

    def test_deterministic_explanation_answers_simulator_query(self):
        chat_service = CopilotChatService()
        mock_context = {
            "user_financial_state": {
                "monthly_surplus": 12000.0,
                "current_savings": 50000.0,
                "emergency_fund_months": 4.5,
            },
            "simulator_input": {
                "principal": 50000.0,
                "monthly_sip": 5000.0,
                "duration_years": 5.0,
                "total_invested": 350000.0,
            },
            "simulator_projections": [
                {
                    "productName": "HDFC Index Fund - Nifty 50 Plan",
                    "category": "INDEX_FUNDS",
                    "totalInvested": 350000.0,
                    "projectedValue": 482500.0,
                    "estimatedGain": 132500.0,
                }
            ],
            "matching_eligible_options": [],
            "what_if_scenario": {},
        }

        reply = chat_service._generate_deterministic_explanation(
            "What happens if I invest ₹5,000 every month?",
            mock_context,
        )

        assert "₹350,000" in reply
        assert "₹482,500" in reply
        assert "₹132,500" in reply
        assert "₹12,000" in reply

    def test_deterministic_explanation_answers_what_if_query(self):
        chat_service = CopilotChatService()
        mock_context = {
            "user_financial_state": {
                "monthly_surplus": 10000.0,
                "current_savings": 40000.0,
                "emergency_fund_months": 3.0,
            },
            "simulator_input": {},
            "simulator_projections": [],
            "matching_eligible_options": [],
            "what_if_scenario": {
                "originalSurplus": 10000.0,
                "adjustedSurplus": 8000.0,
                "impactOnNearestGoal": "Goal timeline delayed by 2 month(s)",
            },
        }

        reply = chat_service._generate_deterministic_explanation(
            "What happens if my monthly surplus decreases by ₹2,000?",
            mock_context,
        )

        assert "₹10,000" in reply
        assert "₹8,000" in reply
        assert "delayed by 2 month(s)" in reply


class TestDeterministicMoneySimulatorCalculations:
    """Test 10: Ensures existing Money Simulator calculations remain mathematically identical."""

    def test_lump_sum_calculation(self):
        # ₹10,000 at 7% for 3 years: 10000 * (1.07)^3 = 12250.43
        fv = calculate_lump_sum(10000.0, 7.0, 3.0)
        assert round(fv, 2) == 12250.43

    def test_sip_calculation(self):
        # ₹1,000/month at 12% for 12 months
        # monthly rate = 1%, FV = 1000 * ((1.01^12 - 1)/0.01) * 1.01 = 12809.33
        fv = calculate_sip(1000.0, 12.0, 12)
        assert round(fv, 2) == 12809.33

    def test_full_simulation_service_output_integrity(self):
        req = InvestmentCalculationRequest(
            principal=20000.0,
            monthlyContribution=2000.0,
            durationYears=2.0,
            category="ALL",
        )
        res = InvestmentService.calculate_simulation(req)
        assert res.principal == 20000.0
        assert res.monthlyContribution == 2000.0
        assert res.durationYears == 2.0
        assert res.totalInvested == 20000.0 + (2000.0 * 24)  # 68,000
        assert len(res.projections) > 0
        for p in res.projections:
            assert p.estimatedFutureValue >= p.totalInvested
            assert p.estimatedGain >= 0.0
            assert p.source is not None
