"""Phase 5: Deterministic Indian Income-Tax Planning Engine.

Calculates income tax liability under Old and New Regimes according to
Finance Act 2024 (FY 2024-25 / AY 2025-26) and provisional FY 2025-26 rules.

CRITICAL ARCHITECTURAL CONSTRAINTS:
1. 100% deterministic backend Python execution.
2. LLMs must NEVER calculate or modify tax figures.
3. Versioned and configurable by financial year.
4. Official source: https://www.incometax.gov.in/iec/foportal/ (Finance Act 2024).
5. All calculations are educational estimates, not certified professional tax advice.
"""

from dataclasses import dataclass, field, asdict
from typing import List, Optional, Dict, Any


@dataclass(frozen=True)
class TaxSlab:
    lower_limit: float
    upper_limit: Optional[float]  # None indicates infinity (highest slab)
    rate: float                   # e.g., 0.05 for 5%


@dataclass(frozen=True)
class RegimeConfig:
    regime_name: str              # 'old' or 'new'
    standard_deduction: float     # e.g., 50000.0 or 75000.0
    slabs: List[TaxSlab]
    section_87a_income_limit: float
    section_87a_max_rebate: float
    allows_80c: bool
    allows_80d: bool
    allows_hra: bool
    cess_rate: float = 0.04


@dataclass(frozen=True)
class TaxYearConfig:
    financial_year: str           # e.g., '2024-25'
    assessment_year: str          # e.g., '2025-26'
    is_verified: bool
    is_provisional: bool
    source: str
    source_url: str
    old_regime: RegimeConfig
    new_regime: RegimeConfig
    disclaimer: str


DISCLAIMER_TEXT = (
    "DISCLAIMER: This calculation is strictly for educational and planning purposes "
    "and does not constitute certified legal, tax, or accounting advice. Tax liability "
    "may vary based on individual circumstances, filing status, and special exemptions. "
    "Please consult a certified Chartered Accountant (CA) or official Income Tax department "
    "guidelines at https://www.incometax.gov.in/iec/foportal/ before filing returns."
)

# FY 2024-25 (AY 2025-26) - Verified under Finance Act 2024
_FY2024_25 = TaxYearConfig(
    financial_year="2024-25",
    assessment_year="2025-26",
    is_verified=True,
    is_provisional=False,
    source="Finance Act 2024, Ministry of Finance, Government of India",
    source_url="https://www.incometax.gov.in/iec/foportal/",
    old_regime=RegimeConfig(
        regime_name="old",
        standard_deduction=50000.0,
        slabs=[
            TaxSlab(0.0, 250000.0, 0.0),
            TaxSlab(250000.0, 500000.0, 0.05),
            TaxSlab(500000.0, 1000000.0, 0.20),
            TaxSlab(1000000.0, None, 0.30),
        ],
        section_87a_income_limit=500000.0,
        section_87a_max_rebate=12500.0,
        allows_80c=True,
        allows_80d=True,
        allows_hra=True,
        cess_rate=0.04,
    ),
    new_regime=RegimeConfig(
        regime_name="new",
        standard_deduction=75000.0,
        slabs=[
            TaxSlab(0.0, 300000.0, 0.0),
            TaxSlab(300000.0, 600000.0, 0.05),
            TaxSlab(600000.0, 900000.0, 0.10),
            TaxSlab(900000.0, 1200000.0, 0.15),
            TaxSlab(1200000.0, 1500000.0, 0.20),
            TaxSlab(1500000.0, None, 0.30),
        ],
        section_87a_income_limit=700000.0,
        section_87a_max_rebate=25000.0,
        allows_80c=False,
        allows_80d=False,
        allows_hra=False,
        cess_rate=0.04,
    ),
    disclaimer=DISCLAIMER_TEXT,
)

# FY 2025-26 (AY 2026-27) - Provisional / Estimated rules
_FY2025_26 = TaxYearConfig(
    financial_year="2025-26",
    assessment_year="2026-27",
    is_verified=False,
    is_provisional=True,
    source="Provisional Budget Proposals 2025 (Subject to Finance Act 2025 enactment)",
    source_url="https://www.incometax.gov.in/iec/foportal/",
    old_regime=RegimeConfig(
        regime_name="old",
        standard_deduction=50000.0,
        slabs=[
            TaxSlab(0.0, 250000.0, 0.0),
            TaxSlab(250000.0, 500000.0, 0.05),
            TaxSlab(500000.0, 1000000.0, 0.20),
            TaxSlab(1000000.0, None, 0.30),
        ],
        section_87a_income_limit=500000.0,
        section_87a_max_rebate=12500.0,
        allows_80c=True,
        allows_80d=True,
        allows_hra=True,
        cess_rate=0.04,
    ),
    new_regime=RegimeConfig(
        regime_name="new",
        standard_deduction=75000.0,
        slabs=[
            TaxSlab(0.0, 400000.0, 0.0),
            TaxSlab(400000.0, 800000.0, 0.05),
            TaxSlab(800000.0, 1200000.0, 0.10),
            TaxSlab(1200000.0, 1600000.0, 0.15),
            TaxSlab(1600000.0, 2000000.0, 0.20),
            TaxSlab(2000000.0, 2400000.0, 0.25),
            TaxSlab(2400000.0, None, 0.30),
        ],
        section_87a_income_limit=700000.0,
        section_87a_max_rebate=25000.0,
        allows_80c=False,
        allows_80d=False,
        allows_hra=False,
        cess_rate=0.04,
    ),
    disclaimer=DISCLAIMER_TEXT,
)

TAX_YEAR_REGISTRY: Dict[str, TaxYearConfig] = {
    "2024-25": _FY2024_25,
    "2025-26": _FY2025_26,
}

DEFAULT_TAX_YEAR = "2024-25"


def get_tax_config(financial_year: str = DEFAULT_TAX_YEAR) -> TaxYearConfig:
    """Retrieves the verified/provisional tax configuration for the specified financial year."""
    if financial_year not in TAX_YEAR_REGISTRY:
        raise ValueError(f"Unsupported financial year: {financial_year}. Supported years: {list(TAX_YEAR_REGISTRY.keys())}")
    return TAX_YEAR_REGISTRY[financial_year]


def list_tax_years() -> List[Dict[str, Any]]:
    """Lists all registered tax years with verification status and sources."""
    return [
        {
            "financialYear": cfg.financial_year,
            "assessmentYear": cfg.assessment_year,
            "isVerified": cfg.is_verified,
            "isProvisional": cfg.is_provisional,
            "source": cfg.source,
            "sourceUrl": cfg.source_url,
        }
        for cfg in TAX_YEAR_REGISTRY.values()
    ]


@dataclass
class TaxInput:
    gross_salary: float = 0.0
    income_from_other_sources: float = 0.0
    business_income: float = 0.0
    deduction_80c: float = 0.0        # PPF, ELSS, EPF, etc. (capped at 1.5L)
    deduction_80d: float = 0.0        # Health Insurance (capped at 25k/50k)
    deduction_80ccd_1b: float = 0.0   # Additional NPS (capped at 50k)
    deduction_hra: float = 0.0        # House Rent Allowance exemption
    other_exemptions: float = 0.0     # Other Chapter VI-A deductions
    financial_year: str = DEFAULT_TAX_YEAR

    def validate(self) -> None:
        if self.gross_salary < 0:
            raise ValueError("Gross salary cannot be negative")
        if self.income_from_other_sources < 0:
            raise ValueError("Other income cannot be negative")
        if self.business_income < 0:
            raise ValueError("Business income cannot be negative")
        if self.deduction_80c < 0:
            raise ValueError("Section 80C deduction cannot be negative")
        if self.deduction_80d < 0:
            raise ValueError("Section 80D deduction cannot be negative")
        if self.deduction_80ccd_1b < 0:
            raise ValueError("Section 80CCD(1B) deduction cannot be negative")
        if self.deduction_hra < 0:
            raise ValueError("HRA deduction cannot be negative")
        if self.other_exemptions < 0:
            raise ValueError("Other exemptions cannot be negative")


@dataclass
class RegimeTaxResult:
    regime: str
    gross_income: float
    standard_deduction: float
    chapter_via_deductions: float
    total_deductions: float
    taxable_income: float
    slab_breakdowns: List[Dict[str, Any]]
    base_tax: float
    rebate_87a: float
    marginal_relief: float
    tax_after_rebate: float
    cess: float
    total_tax: float
    effective_tax_rate: float


@dataclass
class TaxResult:
    financial_year: str
    assessment_year: str
    is_provisional: bool
    source: str
    source_url: str
    disclaimer: str
    gross_income: float
    old_regime: RegimeTaxResult
    new_regime: RegimeTaxResult
    recommended_regime: str
    tax_savings: float
    breakeven_deduction: float
    recommendation_summary: str


def _calculate_regime_tax(
    gross_income: float,
    gross_salary: float,
    deductions_claimed: Dict[str, float],
    regime_cfg: RegimeConfig,
) -> RegimeTaxResult:
    """Calculates tax liability deterministically for a single regime."""
    # Standard deduction applies to salaried income up to salary amount
    std_deduction = min(regime_cfg.standard_deduction, gross_salary) if gross_salary > 0 else 0.0

    # Chapter VI-A deductions allowed in this regime
    chapter_via = 0.0
    if regime_cfg.allows_80c:
        chapter_via += min(deductions_claimed.get("80c", 0.0), 150000.0)
    if regime_cfg.allows_80d:
        chapter_via += min(deductions_claimed.get("80d", 0.0), 50000.0)
    if regime_cfg.allows_80c:  # 80CCD(1B) allowed in Old regime
        chapter_via += min(deductions_claimed.get("80ccd_1b", 0.0), 50000.0)
    if regime_cfg.allows_hra:
        chapter_via += deductions_claimed.get("hra", 0.0)
    if regime_cfg.allows_80c:
        chapter_via += deductions_claimed.get("other", 0.0)

    total_deductions = std_deduction + chapter_via
    taxable_income = max(0.0, gross_income - total_deductions)

    # Compute tax across slabs
    slab_breakdowns = []
    base_tax = 0.0
    for slab in regime_cfg.slabs:
        if taxable_income <= slab.lower_limit:
            break
        upper = slab.upper_limit if slab.upper_limit is not None else taxable_income
        amount_in_slab = min(taxable_income, upper) - slab.lower_limit
        if amount_in_slab > 0:
            slab_tax = amount_in_slab * slab.rate
            base_tax += slab_tax
            slab_name = (
                f"Rs {int(slab.lower_limit):,} to Rs {int(slab.upper_limit):,}"
                if slab.upper_limit is not None
                else f"Above Rs {int(slab.lower_limit):,}"
            )
            slab_breakdowns.append({
                "slab": slab_name,
                "rate": slab.rate,
                "ratePercent": f"{int(slab.rate * 100)}%",
                "taxableInSlab": round(amount_in_slab, 2),
                "taxForSlab": round(slab_tax, 2),
            })

    # Section 87A rebate
    rebate_87a = 0.0
    marginal_relief = 0.0

    if taxable_income <= regime_cfg.section_87a_income_limit:
        rebate_87a = min(base_tax, regime_cfg.section_87a_max_rebate)
        tax_after_rebate = max(0.0, base_tax - rebate_87a)
    else:
        # Marginal relief for New Regime (income slightly above 7 Lakhs)
        if regime_cfg.regime_name == "new" and taxable_income > 700000.0:
            excess_income = taxable_income - 700000.0
            if base_tax > excess_income:
                marginal_relief = base_tax - excess_income
                base_tax = excess_income
        tax_after_rebate = base_tax

    # Health & Education Cess (4%)
    cess = round(tax_after_rebate * regime_cfg.cess_rate, 2)
    total_tax = round(tax_after_rebate + cess, 2)

    effective_rate = round((total_tax / gross_income * 100), 2) if gross_income > 0 else 0.0

    return RegimeTaxResult(
        regime=regime_cfg.regime_name,
        gross_income=round(gross_income, 2),
        standard_deduction=round(std_deduction, 2),
        chapter_via_deductions=round(chapter_via, 2),
        total_deductions=round(total_deductions, 2),
        taxable_income=round(taxable_income, 2),
        slab_breakdowns=slab_breakdowns,
        base_tax=round(base_tax, 2),
        rebate_87a=round(rebate_87a, 2),
        marginal_relief=round(marginal_relief, 2),
        tax_after_rebate=round(tax_after_rebate, 2),
        cess=round(cess, 2),
        total_tax=round(total_tax, 2),
        effective_tax_rate=effective_rate,
    )


def calculate_tax(tax_input: TaxInput) -> TaxResult:
    """Calculates Old and New regime tax liabilities deterministically, compares them,
    and returns a structured planning result with recommendations.
    """
    tax_input.validate()
    cfg = get_tax_config(tax_input.financial_year)

    gross_income = (
        tax_input.gross_salary
        + tax_input.income_from_other_sources
        + tax_input.business_income
    )

    deductions = {
        "80c": tax_input.deduction_80c,
        "80d": tax_input.deduction_80d,
        "80ccd_1b": tax_input.deduction_80ccd_1b,
        "hra": tax_input.deduction_hra,
        "other": tax_input.other_exemptions,
    }

    old_result = _calculate_regime_tax(gross_income, tax_input.gross_salary, deductions, cfg.old_regime)
    new_result = _calculate_regime_tax(gross_income, tax_input.gross_salary, deductions, cfg.new_regime)

    # Determine recommendation
    if new_result.total_tax < old_result.total_tax:
        recommended = "new"
        savings = round(old_result.total_tax - new_result.total_tax, 2)
        summary = (
            f"The New Tax Regime saves you Rs {savings:,.2f} in taxes for FY {cfg.financial_year}. "
            "With the enhanced Rs 75,000 standard deduction and lower slab rates, it offers better net savings."
        )
    elif old_result.total_tax < new_result.total_tax:
        recommended = "old"
        savings = round(new_result.total_tax - old_result.total_tax, 2)
        summary = (
            f"The Old Tax Regime saves you Rs {savings:,.2f} in taxes for FY {cfg.financial_year}. "
            "Your itemized deductions (80C, 80D, HRA) exceed the breakeven threshold, making Old Regime optimal."
        )
    else:
        recommended = "new"
        savings = 0.0
        summary = (
            f"Both regimes yield identical tax liability (Rs {new_result.total_tax:,.2f}) for FY {cfg.financial_year}. "
            "The New Regime is recommended due to simpler tax compliance without needing proof of investments."
        )

    breakeven_deduction = 0.0
    if gross_income > 750000.0:
        breakeven_deduction = 375000.0

    return TaxResult(
        financial_year=cfg.financial_year,
        assessment_year=cfg.assessment_year,
        is_provisional=cfg.is_provisional,
        source=cfg.source,
        source_url=cfg.source_url,
        disclaimer=cfg.disclaimer,
        gross_income=round(gross_income, 2),
        old_regime=old_result,
        new_regime=new_result,
        recommended_regime=recommended,
        tax_savings=savings,
        breakeven_deduction=breakeven_deduction,
        recommendation_summary=summary,
    )
