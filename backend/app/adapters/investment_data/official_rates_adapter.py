"""Official Government & Banking Rates Adapter for Pennora.

Provides officially published, verified card rates for guaranteed savings instruments:
1. Fixed Deposit (FD) - State Bank of India (SBI) Domestic Term Deposit published rates
2. Recurring Deposit (RD) - India Post / National Savings Schemes official schedule
3. Public Provident Fund (PPF) - Ministry of Finance notified sovereign rate
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone
from typing import List

from app.adapters.investment_data.base_adapter import InvestmentSourceAdapter, SourcedProduct

logger = logging.getLogger("pennora.adapters.official_rates")


class OfficialRatesAdapter(InvestmentSourceAdapter):
    """Adapter for official banking and sovereign savings interest rates."""

    OFFICIAL_PRODUCTS = [
        {
            "id": "sbi_term_fd",
            "name": "SBI Domestic Term Fixed Deposit (FD)",
            "category": "FD",
            "provider": "State Bank of India (SBI)",
            "rate": 6.80,
            "min_rate": 6.50,
            "max_rate": 7.10,
            "min_tenure": 12,
            "max_tenure": 120,
            "min_amount": 1000.0,
            "risk": "Low",
            "liquidity": "Moderate",
            "source_name": "State Bank of India (Official Card Rates)",
            "source_url": "https://sbi.co.in/web/personal-banking/investments-deposits/deposits/fixed-deposit",
            "tax_notes": "Interest taxable as per marginal slab. DICGC insurance protection up to ₹5,00,000.",
            "description": "Standard term deposit offering guaranteed fixed returns with premature withdrawal options.",
        },
        {
            "id": "indiapost_rd_5yr",
            "name": "Post Office Recurring Deposit (5-Year RD)",
            "category": "RD",
            "provider": "Department of Posts / Ministry of Communications",
            "rate": 6.70,
            "min_rate": 6.70,
            "max_rate": 6.70,
            "min_tenure": 12,
            "max_tenure": 60,
            "min_amount": 500.0,
            "risk": "Low",
            "liquidity": "Moderate",
            "source_name": "India Post / National Savings Schemes",
            "source_url": "https://www.indiapost.gov.in/Financial/Pages/Content/Recurring-Deposit.aspx",
            "tax_notes": "Interest is taxable. No TDS deducted by post office for national savings RD.",
            "description": "Quarterly compounded disciplined monthly deposit with sovereign guarantee.",
        },
        {
            "id": "mof_ppf_scheme",
            "name": "Public Provident Fund (PPF Scheme 2019)",
            "category": "PPF",
            "provider": "Ministry of Finance, Government of India",
            "rate": 7.10,
            "min_rate": 7.10,
            "max_rate": 7.10,
            "min_tenure": 60,
            "max_tenure": 180,
            "min_amount": 500.0,
            "risk": "Low",
            "liquidity": "Lock-in",
            "source_name": "Ministry of Finance (DEA Gazette Notification)",
            "source_url": "https://www.dea.gov.in/sites/default/files/SmallSavingsRates.pdf",
            "tax_notes": "Exempt-Exempt-Exempt (EEE) status: Principal (80C), interest, and maturity proceeds are 100% tax-free.",
            "description": "15-year sovereign savings vehicle with full tax exemption and guaranteed annual compounded interest.",
        },
    ]

    @property
    def source_name(self) -> str:
        return "Government of India & Public Sector Banks"

    @property
    def source_url(self) -> str:
        return "https://www.dea.gov.in"

    def fetch_products(self) -> List[SourcedProduct]:
        """Returns verified official fixed income products."""
        now = datetime.now(timezone.utc)
        as_of = now.strftime("%d-%b-%Y")
        products: List[SourcedProduct] = []

        for item in self.OFFICIAL_PRODUCTS:
            products.append(
                SourcedProduct(
                    id=item["id"],
                    name=item["name"],
                    category=item["category"],
                    provider=item["provider"],
                    rate_or_nav=item["rate"],
                    assumed_annual_rate_min=item["min_rate"],
                    assumed_annual_rate_max=item["max_rate"],
                    min_tenure_months=item["min_tenure"],
                    max_tenure_months=item["max_tenure"],
                    min_amount=item["min_amount"],
                    risk=item["risk"],
                    liquidity=item["liquidity"],
                    source_name=item["source_name"],
                    source_url=item["source_url"],
                    as_of_date=as_of,
                    tax_notes=item["tax_notes"],
                    is_guaranteed=True,
                    is_live_data=False,
                    status="active",
                    description=item["description"],
                    fetched_at=now,
                )
            )

        return products
