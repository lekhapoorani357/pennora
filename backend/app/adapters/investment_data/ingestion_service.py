"""Investment Data Ingestion & Freshness Management Service.

Coordinates official data adapters (AMFI, NSE, Ministry of Finance/SBI) to synchronize
verified investment products into the database with source attribution and freshness checks.
"""

from __future__ import annotations

import logging
from datetime import datetime, timezone, timedelta
from typing import Any, Dict, List, Optional

from app.adapters.investment_data.base_adapter import InvestmentSourceAdapter, SourcedProduct
from app.adapters.investment_data.amfi_adapter import AmfiAdapter
from app.adapters.investment_data.nse_adapter import NseAdapter
from app.adapters.investment_data.official_rates_adapter import OfficialRatesAdapter
from app.database import get_collection

logger = logging.getLogger("pennora.adapters.ingestion")

STALE_DATA_THRESHOLD_DAYS = 7


class InvestmentIngestionService:
    """Synchronizes sourced investment products into the Pennora database."""

    def __init__(self, adapters: Optional[List[InvestmentSourceAdapter]] = None):
        self.adapters = adapters or [
            AmfiAdapter(),
            NseAdapter(),
            OfficialRatesAdapter(),
        ]

    def sync_all_adapters(self) -> Dict[str, Any]:
        """Runs all adapters and upserts products into the database."""
        now = datetime.now(timezone.utc)
        coll = get_collection("investment_products")
        total_synced = 0
        details = []

        for adapter in self.adapters:
            try:
                products = adapter.fetch_products()
                for prod in products:
                    doc = prod.to_dict()
                    prod_id = prod.id

                    # Check existing to preserve or update
                    existing = coll.find_one({"_id": prod_id})
                    if existing:
                        coll.update_one(
                            {"_id": prod_id},
                            {
                                "$set": {
                                    "name": prod.name,
                                    "category": prod.category,
                                    "provider": prod.provider,
                                    "rate_or_nav": prod.rate_or_nav,
                                    "assumedAnnualRateMin": prod.assumed_annual_rate_min,
                                    "assumedAnnualRateMax": prod.assumed_annual_rate_max,
                                    "minTenureMonths": prod.min_tenure_months,
                                    "maxTenureMonths": prod.max_tenure_months,
                                    "minAmount": prod.min_amount,
                                    "risk": prod.risk,
                                    "liquidity": prod.liquidity,
                                    "source": prod.source_name,
                                    "source_name": prod.source_name,
                                    "source_url": prod.source_url,
                                    "as_of_date": prod.as_of_date,
                                    "taxNotes": prod.tax_notes,
                                    "isGuaranteed": prod.is_guaranteed,
                                    "is_live_data": prod.is_live_data,
                                    "status": prod.status,
                                    "description": prod.description,
                                    "fetched_at": now,
                                    "updatedAt": now,
                                    "isDemo": False,
                                }
                            },
                        )
                    else:
                        coll.insert_one(doc)

                    total_synced += 1

                details.append({
                    "source": adapter.source_name,
                    "products_count": len(products),
                    "status": "success",
                })
            except Exception as e:
                logger.error("Failed to sync adapter %s: %s", adapter.source_name, e)
                details.append({
                    "source": adapter.source_name,
                    "error": str(e),
                    "status": "failed",
                })

        return {
            "total_synced": total_synced,
            "synced_at": now.isoformat(),
            "sources": details,
        }

    def get_all_products(self, category: Optional[str] = None) -> List[Dict[str, Any]]:
        """Retrieves products from the database, evaluating freshness."""
        coll = get_collection("investment_products")
        query: Dict[str, Any] = {}
        if category and category.upper() != "ALL":
            query["category"] = category.upper()

        cursor = coll.find(query)
        products = list(cursor)

        # If DB is empty, run sync on first access
        if not products:
            self.sync_all_adapters()
            products = list(coll.find(query))

        now = datetime.now(timezone.utc)
        results = []
        for p in products:
            p["_id"] = str(p["_id"])
            p["id"] = p["_id"]

            # Evaluate freshness
            fetched_at_raw = p.get("fetched_at")
            if fetched_at_raw:
                try:
                    if isinstance(fetched_at_raw, str):
                        f_dt = datetime.fromisoformat(fetched_at_raw.replace("Z", "+00:00"))
                    else:
                        f_dt = fetched_at_raw
                    if f_dt.tzinfo is None:
                        f_dt = f_dt.replace(tzinfo=timezone.utc)
                    if (now - f_dt) > timedelta(days=STALE_DATA_THRESHOLD_DAYS):
                        p["status"] = "stale"
                except Exception:
                    pass

            results.append(p)

        return results


# Global singleton instance
_ingestion_service_instance: Optional[InvestmentIngestionService] = None


def get_investment_ingestion_service() -> InvestmentIngestionService:
    global _ingestion_service_instance
    if _ingestion_service_instance is None:
        _ingestion_service_instance = InvestmentIngestionService()
    return _ingestion_service_instance
