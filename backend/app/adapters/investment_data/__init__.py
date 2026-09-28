"""Investment data adapters package."""

from app.adapters.investment_data.base_adapter import InvestmentSourceAdapter, SourcedProduct
from app.adapters.investment_data.amfi_adapter import AmfiAdapter
from app.adapters.investment_data.nse_adapter import NseAdapter
from app.adapters.investment_data.official_rates_adapter import OfficialRatesAdapter
from app.adapters.investment_data.ingestion_service import (
    InvestmentIngestionService,
    get_investment_ingestion_service,
)

__all__ = [
    "InvestmentSourceAdapter",
    "SourcedProduct",
    "AmfiAdapter",
    "NseAdapter",
    "OfficialRatesAdapter",
    "InvestmentIngestionService",
    "get_investment_ingestion_service",
]
