"""Base Adapter for Real Sourced Investment Products in Pennora.

Provides standard interface and data schemas for official financial data sources
(AMFI, NSE India, Ministry of Finance, RBI, Nationalized Banks).
"""

from __future__ import annotations

from abc import ABC, abstractmethod
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional


@dataclass
class SourcedProduct:
    """Standard representation of an investment product retrieved from an official source."""

    id: str
    name: str
    category: str  # FD, RD, PPF, MUTUAL_FUNDS, INDEX_FUNDS, EQUITY, GOV_SECURITIES, T_BILLS
    provider: str
    rate_or_nav: float
    assumed_annual_rate_min: float
    assumed_annual_rate_max: float
    min_tenure_months: int
    max_tenure_months: int
    min_amount: float
    risk: str  # Low, Moderate, High, Very High
    liquidity: str  # High, Moderate, Lock-in
    source_name: str
    source_url: str
    as_of_date: str
    tax_notes: Optional[str] = None
    is_guaranteed: bool = False
    is_live_data: bool = False
    status: str = "active"  # active, cached, stale
    description: Optional[str] = None
    fetched_at: Optional[datetime] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "_id": self.id,
            "id": self.id,
            "name": self.name,
            "product_name": self.name,
            "category": self.category,
            "product_type": self.category,
            "provider": self.provider,
            "rate_or_nav": self.rate_or_nav,
            "assumedAnnualRateMin": self.assumed_annual_rate_min,
            "assumedAnnualRateMax": self.assumed_annual_rate_max,
            "minTenureMonths": self.min_tenure_months,
            "maxTenureMonths": self.max_tenure_months,
            "minAmount": self.min_amount,
            "minimum_amount": self.min_amount,
            "risk": self.risk,
            "risk_level": self.risk,
            "liquidity": self.liquidity,
            "source": self.source_name,
            "source_name": self.source_name,
            "source_url": self.source_url,
            "as_of_date": self.as_of_date,
            "taxNotes": self.tax_notes,
            "isGuaranteed": self.is_guaranteed,
            "is_live_data": self.is_live_data,
            "status": self.status,
            "description": self.description,
            "fetched_at": (self.fetched_at or datetime.now(timezone.utc)).isoformat(),
            "isDemo": False,
        }


class InvestmentSourceAdapter(ABC):
    """Abstract interface for official investment product data adapters."""

    @property
    @abstractmethod
    def source_name(self) -> str:
        """Name of the official regulatory or financial institution source."""
        pass

    @property
    @abstractmethod
    def source_url(self) -> str:
        """Primary official web endpoint or portal for verification."""
        pass

    @abstractmethod
    def fetch_products(self) -> List[SourcedProduct]:
        """Fetches and normalizes investment products from the official source."""
        pass
