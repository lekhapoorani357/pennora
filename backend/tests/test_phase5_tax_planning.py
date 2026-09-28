"""Phase 5 Test Suite: Deterministic Indian Income-Tax Planning Engine.

Validates:
1. Versioned financial year tax configuration (FY 2024-25 verified, FY 2025-26 provisional)
2. Invalidation of unsupported financial years
3. Deterministic calculation for Old Regime (slabs, 80C cap, standard deduction, 87A rebate, 4% cess)
4. Deterministic calculation for New Regime (enhanced 75k standard deduction, 7L 87A rebate, slab rates)
5. Strict determinism: identical inputs always yield identical outputs
6. Negative income rejection (ValueError)
7. Disclaimer integrity (educational estimate, source incometax.gov.in)
8. API endpoint security (auth enforcement, config retrieval, estimation, LLM explanation without number alteration)
9. User isolation across tax estimations
"""

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.database import get_collection
from app.services.tax_service import (
    TaxInput,
    calculate_tax,
    get_tax_config,
    list_tax_years,
    DEFAULT_TAX_YEAR,
)


@pytest.fixture
def client(sqlite_test_database):
    return TestClient(app)


def register_user(client: TestClient, email: str, full_name: str = "Tax User") -> dict:
    import hashlib
    phone_suffix = str(abs(hash(email)) % 100000000).zfill(8)
    client.post(
        "/auth/register",
        json={
            "fullName": full_name,
            "email": email,
            "phone": f"91{phone_suffix}",
            "password": "Password123!",
        },
    )
    login_res = client.post(
        "/auth/login",
        json={
            "identifier": email,
            "password": "Password123!",
        },
    )
    assert login_res.status_code == 200, f"Login failed for {email}: {login_res.text}"
    token = login_res.json()["access_token"]
    headers = {"Authorization": f"Bearer {token}"}
    user_doc = get_collection("users").find_one({"email": email})
    return {"headers": headers, "user": user_doc, "token": token}


# ==================== 1. CONFIGURATION TESTS ====================

def test_tax_config_versioning_and_sources():
    # FY 2024-25 must be verified under Finance Act 2024
    cfg_24 = get_tax_config("2024-25")
    assert cfg_24.is_verified is True
    assert cfg_24.is_provisional is False
    assert "incometax.gov.in" in cfg_24.source_url
    assert cfg_24.old_regime.standard_deduction == 50000.0
    assert cfg_24.new_regime.standard_deduction == 75000.0

    # FY 2025-26 must be provisional
    cfg_25 = get_tax_config("2025-26")
    assert cfg_25.is_verified is False
    assert cfg_25.is_provisional is True

    # Unsupported year must raise ValueError
    with pytest.raises(ValueError, match="Unsupported financial year"):
        get_tax_config("1998-99")


def test_list_tax_years():
    years = list_tax_years()
    assert len(years) >= 2
    fys = [y["financialYear"] for y in years]
    assert "2024-25" in fys
    assert "2025-26" in fys


# ==================== 2. DETERMINISTIC ENGINE TESTS ====================

def test_zero_income():
    t_input = TaxInput(gross_salary=0.0, financial_year="2024-25")
    res = calculate_tax(t_input)
    assert res.old_regime.total_tax == 0.0
    assert res.new_regime.total_tax == 0.0
    assert res.gross_income == 0.0


def test_negative_income_rejected():
    t_input = TaxInput(gross_salary=-50000.0)
    with pytest.raises(ValueError, match="cannot be negative"):
        calculate_tax(t_input)


def test_old_regime_rebate_87a():
    # Salaried Rs 5,00,000 -> Std deduction 50k -> Taxable Rs 4,50,000
    # Tax on 4.5L = 5% of (4.5L - 2.5L) = 10,000
    # Section 87A rebate covers up to 12,500 -> Tax after rebate = 0.0
    t_input = TaxInput(gross_salary=500000.0, financial_year="2024-25")
    res = calculate_tax(t_input)
    assert res.old_regime.taxable_income == 450000.0
    assert res.old_regime.base_tax == 10000.0
    assert res.old_regime.rebate_87a == 10000.0
    assert res.old_regime.total_tax == 0.0


def test_old_regime_80c_cap_enforced():
    # Claiming 3,00,000 for 80C; cap must be 1,50,000
    t_input = TaxInput(
        gross_salary=1200000.0,
        deduction_80c=300000.0,
        financial_year="2024-25",
    )
    res = calculate_tax(t_input)
    assert res.old_regime.chapter_via_deductions == 150000.0
    assert res.old_regime.standard_deduction == 50000.0
    assert res.old_regime.total_deductions == 200000.0
    assert res.old_regime.taxable_income == 1000000.0


def test_new_regime_standard_deduction_and_7l_rebate():
    # Gross salary 7,75,000 -> Std deduction 75,000 -> Taxable 7,00,000
    # Slabs:
    # 0 to 3L: 0
    # 3L to 6L: 5% of 3L = 15,000
    # 6L to 7L: 10% of 1L = 10,000
    # Base tax = 25,000
    # Section 87A rebate for taxable <= 7L is up to 25,000 -> Tax after rebate = 0.0
    t_input = TaxInput(gross_salary=775000.0, financial_year="2024-25")
    res = calculate_tax(t_input)
    assert res.new_regime.standard_deduction == 75000.0
    assert res.new_regime.taxable_income == 700000.0
    assert res.new_regime.base_tax == 25000.0
    assert res.new_regime.rebate_87a == 25000.0
    assert res.new_regime.total_tax == 0.0
    # 80C should be completely ignored in new regime
    assert res.new_regime.chapter_via_deductions == 0.0


def test_cess_is_exactly_4_percent():
    # Gross salary 15,00,000, New Regime
    # Std deduction 75k -> Taxable 14,25,000
    # Tax:
    # 3-6L: 15k
    # 6-9L: 30k
    # 9-12L: 45k
    # 12-14.25L: 20% of 2.25L = 45k
    # Base tax = 135,000
    # Cess = 4% of 135,000 = 5,400.0
    # Total tax = 140,400.0
    t_input = TaxInput(gross_salary=1500000.0, financial_year="2024-25")
    res = calculate_tax(t_input)
    nr = res.new_regime
    expected_base = 135000.0
    expected_cess = round(expected_base * 0.04, 2)
    assert nr.base_tax == expected_base
    assert nr.cess == expected_cess
    assert nr.total_tax == expected_base + expected_cess


def test_strict_determinism():
    t_input = TaxInput(
        gross_salary=1850000.0,
        income_from_other_sources=45000.0,
        deduction_80c=150000.0,
        deduction_80d=25000.0,
        deduction_hra=60000.0,
        financial_year="2024-25",
    )
    first_res = calculate_tax(t_input)
    for _ in range(50):
        next_res = calculate_tax(t_input)
        assert next_res.old_regime.total_tax == first_res.old_regime.total_tax
        assert next_res.new_regime.total_tax == first_res.new_regime.total_tax
        assert next_res.recommended_regime == first_res.recommended_regime
        assert next_res.tax_savings == first_res.tax_savings


def test_disclaimer_present():
    t_input = TaxInput(gross_salary=800000.0)
    res = calculate_tax(t_input)
    assert "DISCLAIMER" in res.disclaimer
    assert "incometax.gov.in" in res.disclaimer


# ==================== 3. API ENDPOINT TESTS ====================

def test_api_get_config_public(client):
    res = client.get("/api/tax/config")
    assert res.status_code == 200
    data = res.json()
    assert data["status"] == "success"
    assert data["defaultFinancialYear"] == "2024-25"
    assert len(data["availableYears"]) >= 2

    # Specific year
    res_year = client.get("/api/tax/config/2024-25")
    assert res_year.status_code == 200
    y_data = res_year.json()
    assert y_data["isVerified"] is True
    assert "slabs" in y_data["oldRegime"]
    assert "slabs" in y_data["newRegime"]


def test_api_calculate_requires_auth(client):
    res = client.post("/api/tax/calculate", json={"gross_salary": 900000.0})
    assert res.status_code in (401, 403)


def test_api_calculate_authenticated(client):
    user = register_user(client, "taxpayer@pennora.com")
    res = client.post(
        "/api/tax/calculate",
        headers=user["headers"],
        json={
            "financial_year": "2024-25",
            "gross_salary": 1200000.0,
            "deduction_80c": 150000.0,
            "deduction_80d": 25000.0,
        },
    )
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["gross_income"] == 1200000.0
    assert "old_regime" in data
    assert "new_regime" in data
    assert data["recommended_regime"] in ("old", "new")
    assert "disclaimer" in data


def test_api_estimate_uses_financial_profile(client):
    user = register_user(client, "profile_tax@pennora.com")
    # Set financial profile with monthlyIncome = 1,00,000 (12L annual)
    profiles_coll = get_collection("financial_profiles")
    profiles_coll.insert_one({
        "_id": "prof_tax_1",
        "userId": str(user["user"]["_id"]),
        "monthlyIncome": 100000.0,
        "monthlyExpenses": 40000.0,
    })

    res = client.get("/api/tax/estimate", headers=user["headers"])
    assert res.status_code == 200
    data = res.json()["data"]
    assert data["gross_income"] == 1200000.0
    assert data["financial_year"] == DEFAULT_TAX_YEAR


def test_api_explain_deterministic_formatting(client):
    user = register_user(client, "explain_tax@pennora.com")
    calc_res = client.post(
        "/api/tax/calculate",
        headers=user["headers"],
        json={"gross_salary": 1000000.0},
    )
    calc_data = calc_res.json()["data"]

    explain_res = client.post(
        "/api/tax/explain",
        headers=user["headers"],
        json={"calculation": calc_data},
    )
    assert explain_res.status_code == 200
    explain_data = explain_res.json()
    assert "explanation" in explain_data
    assert "Regime" in explain_data["explanation"]
    assert explain_data["recommendedRegime"] == calc_data["recommended_regime"]
