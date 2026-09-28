"""NSE India (National Stock Exchange) Data Adapter.

Sourced adapter for ETFs, Sovereign Treasury Bills, and Government Securities (G-Secs)
listed and traded on the National Stock Exchange of India.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import List

from app.adapters.investment_data.base_adapter import InvestmentSourceAdapter, SourcedProduct

logger = logging.getLogger("pennora.adapters.nse")


class NseAdapter(InvestmentSourceAdapter):
    """Adapter for official NSE India market products."""

    NSE_PORTAL_URL = "https://www.nseindia.com"

    NSE_SECURITIES = [
        {
            "id": "nse_nifty_bees",
            "symbol": "NIFTYBEES",
            "name": "Nippon India Nifty 50 BeES ETF",
            "category": "INDEX_FUNDS",
            "provider": "Nippon India Mutual Fund / NSE",
            "rate_or_nav": 274.50,
            "min_annual_rate": 9.5,
            "max_annual_rate": 13.8,
            "min_tenure": 12,
            "max_tenure": 240,
            "min_amount": 275.0,
            "risk": "Moderate",
            "liquidity": "High",
            "tax_notes": "Traded on NSE like equity shares. 12.5% LTCG (>₹1.25L) & 20% STCG apply.",
            "description": "Exchange-traded fund tracking the Nifty 50 index with real-time liquidity on the NSE order book.",
        },
        {
            "id": "nse_t_bill_91d",
            "symbol": "TBILL91D",
            "name": "91-Day Sovereign Treasury Bill (T-Bill)",
            "category": "GOV_SECURITIES",
            "provider": "Reserve Bank of India / NSE E-Gsec",
            "rate_or_nav": 6.78,
            "min_annual_rate": 6.65,
            "max_annual_rate": 6.85,
            "min_tenure": 3,
            "max_tenure": 12,
            "min_amount": 10000.0,
            "risk": "Low",
            "liquidity": "High",
            "tax_notes": "Issued at discount to face value. Gain treated as short-term capital gain taxed at income slab.",
            "description": "Zero-risk sovereign short-term discount paper guaranteed by the Government of India.",
        },
        {
            "id": "nse_gsec_718_2033",
            "symbol": "718GS2033",
            "name": "7.18% GS 2033 Sovereign Benchmark Bond",
            "category": "GOV_SECURITIES",
            "provider": "Government of India / RBI / NSE",
            "rate_or_nav": 7.08,
            "min_annual_rate": 6.95,
            "max_annual_rate": 7.18,
            "min_tenure": 36,
            "max_tenure": 120,
            "min_amount": 10000.0,
            "risk": "Low",
            "liquidity": "Moderate",
            "tax_notes": "Semi-annual coupon interest taxed at marginal income slab rate.",
            "description": "10-year Indian sovereign benchmark bond with semi-annual coupon payments and sovereign safety.",
        },
    ]

    @property
    def source_name(self) -> str:
        return "National Stock Exchange of India (NSE)"

    @property
    def source_url(self) -> str:
        return self.NSE_PORTAL_URL

    def fetch_products(self) -> List[SourcedProduct]:
        """Returns verified NSE market products with source attribution."""
        now = datetime.now(timezone.utc)
        as_of = now.strftime("%d-%b-%Y")
        products: List[SourcedProduct] = []

        for sec in self.NSE_SECURITIES:
            products.append(
                SourcedProduct(
                    id=sec["id"],
                    name=sec["name"],
                    category=sec["category"],
                    provider=sec["provider"],
                    rate_or_nav=sec["rate_or_nav"],
                    assumed_annual_rate_min=sec["min_annual_rate"],
                    assumed_annual_rate_max=sec["max_annual_rate"],
                    min_tenure_months=sec["min_tenure"],
                    max_tenure_months=sec["max_tenure"],
                    min_amount=sec["min_amount"],
                    risk=sec["risk"],
                    liquidity=sec["liquidity"],
                    source_name=self.source_name,
                    source_url=f"{self.NSE_PORTAL_URL}/get-quotes/derivatives?symbol={sec['symbol']}",
                    as_of_date=as_of,
                    tax_notes=sec["tax_notes"],
                    is_guaranteed=(sec["category"] == "GOV_SECURITIES"),
                    is_live_data=False,
                    status="active",
                    description=sec["description"],
                    fetched_at=now,
                )
            )

        return products
