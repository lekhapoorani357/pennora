"""Phase 5: Tax Planning Routes.

Provides REST endpoints for Indian income tax calculation, configurations,
profile-based estimations, and structured AI explanations.
"""

from typing import Optional, Dict, Any
from fastapi import APIRouter, Depends, HTTPException, status
from pydantic import BaseModel, Field

from app.database import get_collection
from app.dependencies import get_current_user
from app.services.tax_service import (
    TaxInput,
    calculate_tax,
    get_tax_config,
    list_tax_years,
    DEFAULT_TAX_YEAR,
    TAX_YEAR_REGISTRY,
    asdict,
)

router = APIRouter(prefix="/api/tax", tags=["Tax Planning"])


class TaxCalculateRequest(BaseModel):
    financial_year: Optional[str] = Field(default=DEFAULT_TAX_YEAR)
    gross_salary: Optional[float] = Field(default=None, ge=0)
    income_from_other_sources: Optional[float] = Field(default=0.0, ge=0)
    business_income: Optional[float] = Field(default=0.0, ge=0)
    deduction_80c: Optional[float] = Field(default=0.0, ge=0)
    deduction_80d: Optional[float] = Field(default=0.0, ge=0)
    deduction_80ccd_1b: Optional[float] = Field(default=0.0, ge=0)
    deduction_hra: Optional[float] = Field(default=0.0, ge=0)
    other_exemptions: Optional[float] = Field(default=0.0, ge=0)


class TaxExplainRequest(BaseModel):
    calculation: Dict[str, Any]


@router.get("/config")
def get_tax_configurations():
    """Returns available financial years with verification status and sources."""
    return {
        "status": "success",
        "defaultFinancialYear": DEFAULT_TAX_YEAR,
        "availableYears": list_tax_years(),
    }


@router.get("/config/{financial_year}")
def get_tax_config_by_year(financial_year: str):
    """Returns the detailed tax regime slabs and rules for a specific financial year."""
    try:
        cfg = get_tax_config(financial_year)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=str(e))

    return {
        "status": "success",
        "financialYear": cfg.financial_year,
        "assessmentYear": cfg.assessment_year,
        "isVerified": cfg.is_verified,
        "isProvisional": cfg.is_provisional,
        "source": cfg.source,
        "sourceUrl": cfg.source_url,
        "disclaimer": cfg.disclaimer,
        "oldRegime": {
            "standardDeduction": cfg.old_regime.standard_deduction,
            "section87aIncomeLimit": cfg.old_regime.section_87a_income_limit,
            "section87aMaxRebate": cfg.old_regime.section_87a_max_rebate,
            "allows80c": cfg.old_regime.allows_80c,
            "allows80d": cfg.old_regime.allows_80d,
            "allowsHra": cfg.old_regime.allows_hra,
            "cessRate": cfg.old_regime.cess_rate,
            "slabs": [asdict(s) for s in cfg.old_regime.slabs],
        },
        "newRegime": {
            "standardDeduction": cfg.new_regime.standard_deduction,
            "section87aIncomeLimit": cfg.new_regime.section_87a_income_limit,
            "section87aMaxRebate": cfg.new_regime.section_87a_max_rebate,
            "allows80c": cfg.new_regime.allows_80c,
            "allows80d": cfg.new_regime.allows_80d,
            "allowsHra": cfg.new_regime.allows_hra,
            "cessRate": cfg.new_regime.cess_rate,
            "slabs": [asdict(s) for s in cfg.new_regime.slabs],
        },
    }


@router.post("/calculate")
def calculate_tax_liability(
    payload: TaxCalculateRequest,
    current_user: dict = Depends(get_current_user),
):
    """Deterministically calculates Old vs New regime tax based on input or user profile."""
    user_id = str(current_user["_id"])
    fy = payload.financial_year or DEFAULT_TAX_YEAR

    gross_sal = payload.gross_salary
    if gross_sal is None:
        profiles_coll = get_collection("financial_profiles")
        profile = profiles_coll.find_one({"userId": user_id})
        if profile and profile.get("monthlyIncome"):
            gross_sal = float(profile["monthlyIncome"]) * 12.0
        else:
            gross_sal = 0.0

    try:
        t_input = TaxInput(
            gross_salary=gross_sal,
            income_from_other_sources=payload.income_from_other_sources or 0.0,
            business_income=payload.business_income or 0.0,
            deduction_80c=payload.deduction_80c or 0.0,
            deduction_80d=payload.deduction_80d or 0.0,
            deduction_80ccd_1b=payload.deduction_80ccd_1b or 0.0,
            deduction_hra=payload.deduction_hra or 0.0,
            other_exemptions=payload.other_exemptions or 0.0,
            financial_year=fy,
        )
        res = calculate_tax(t_input)
    except ValueError as e:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=str(e))

    return {
        "status": "success",
        "data": asdict(res),
    }


@router.get("/estimate")
def get_tax_estimate_from_profile(
    current_user: dict = Depends(get_current_user),
):
    """Calculates tax estimate automatically from user's saved financial profile."""
    user_id = str(current_user["_id"])
    profiles_coll = get_collection("financial_profiles")
    profile = profiles_coll.find_one({"userId": user_id})

    annual_income = 0.0
    if profile:
        monthly = profile.get("monthlyIncome", 0.0) or 0.0
        annual_income = float(monthly) * 12.0

    t_input = TaxInput(
        gross_salary=annual_income,
        financial_year=DEFAULT_TAX_YEAR,
    )
    res = calculate_tax(t_input)
    return {
        "status": "success",
        "data": asdict(res),
    }


@router.post("/explain")
def explain_tax_calculation(
    payload: TaxExplainRequest,
    current_user: dict = Depends(get_current_user),
):
    """Provides a natural language explanation of the already-calculated deterministic tax result.

    CRITICAL: LLM does NOT calculate any tax numbers. It only explains the provided results.
    """
    calc = payload.calculation
    if not calc or "old_regime" not in calc or "new_regime" not in calc:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Invalid calculation payload: old_regime and new_regime results required.",
        )

    old_r = calc["old_regime"]
    new_r = calc["new_regime"]
    recommended = calc.get("recommended_regime", "new")
    savings = calc.get("tax_savings", 0.0)
    fy = calc.get("financial_year", DEFAULT_TAX_YEAR)

    explanation = (
        f"For Financial Year {fy}, under the **{recommended.title()} Regime**, your total tax liability is "
        f"**Rs {calc[recommended + '_regime']['total_tax']:,.2f}**, which saves you **Rs {savings:,.2f}** compared to the other regime.\n\n"
        f"- **New Regime Tax**: Rs {new_r['total_tax']:,.2f} (Standard Deduction: Rs {new_r['standard_deduction']:,.2f}, Taxable: Rs {new_r['taxable_income']:,.2f})\n"
        f"- **Old Regime Tax**: Rs {old_r['total_tax']:,.2f} (Total Deductions: Rs {old_r['total_deductions']:,.2f}, Taxable: Rs {old_r['taxable_income']:,.2f})\n\n"
        f"{calc.get('recommendation_summary', '')}\n\n"
        f"*{calc.get('disclaimer', '')}*"
    )

    return {
        "status": "success",
        "explanation": explanation,
        "recommendedRegime": recommended,
        "taxSavings": savings,
    }
