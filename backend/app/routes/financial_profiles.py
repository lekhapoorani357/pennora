from datetime import datetime, timezone
from fastapi import APIRouter, Depends, HTTPException, status
from app.database import get_collection
from app.dependencies import get_current_user
from app.schemas.financial_profile import (
    RoleSelectionRequest,
    FinancialProfileCreate,
    FinancialProfileUpdate,
    FinancialProfileResponse,
)

router = APIRouter(prefix="/financial-profile", tags=["Financial Profile"])


@router.post("/role", response_model=FinancialProfileResponse, summary="Select or update user's financial role")
def set_financial_role(
    payload: RoleSelectionRequest,
    current_user: dict = Depends(get_current_user),
):
    valid_roles = ["student", "professional", "family"]
    role = payload.role.strip().lower()
    if role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Role must be one of {valid_roles}",
        )

    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    existing = coll.find_one({"userId": user_id})
    if existing:
        coll.update_one({"_id": existing["_id"]}, {"$set": {"financialRole": role, "updatedAt": now}})
        updated = coll.find_one({"_id": existing["_id"]})
        updated["_id"] = str(updated["_id"])
        updated["userId"] = str(updated["userId"])
        return updated

    default_occupation = "Student" if role == "student" else "Professional"
    doc = {
        "userId": user_id,
        "financialRole": role,
        "roleData": None,
        "age": 20 if role == "student" else 28,
        "occupation": default_occupation,
        "dependents": 2 if role == "family" else 0,
        "monthlyIncome": 0.0,
        "incomeType": "Pocket Money/Stipend" if role == "student" else "Salary",
        "additionalIncome": 0.0,
        "currentSavings": 0.0,
        "fixedExpenses": 0.0,
        "variableExpenses": 0.0,
        "monthlyEMI": 0.0,
        "activeLoans": 0,
        "createdAt": now,
        "updatedAt": now,
    }
    res = coll.insert_one(doc)
    doc["_id"] = str(res.inserted_id)
    doc["userId"] = str(doc["userId"])
    return doc


@router.post("", response_model=FinancialProfileResponse, status_code=status.HTTP_201_CREATED)
def create_or_update_profile(
    payload: FinancialProfileCreate,
    current_user: dict = Depends(get_current_user),
):
    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    existing = coll.find_one({"userId": user_id})
    if existing:
        # Update existing profile
        update_data = payload.model_dump()
        update_data["updatedAt"] = now
        coll.update_one({"_id": existing["_id"]}, {"$set": update_data})
        updated = coll.find_one({"_id": existing["_id"]})
        updated["_id"] = str(updated["_id"])
        updated["userId"] = str(updated["userId"])
        return updated

    doc = payload.model_dump()
    doc["userId"] = user_id
    doc["createdAt"] = now
    doc["updatedAt"] = now

    res = coll.insert_one(doc)
    doc["_id"] = str(res.inserted_id)
    doc["userId"] = str(doc["userId"])
    return doc


@router.get("", response_model=FinancialProfileResponse)
def get_profile(current_user: dict = Depends(get_current_user)):
    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])

    doc = coll.find_one({"userId": user_id})
    if not doc:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Financial profile not found for this user.",
        )
    doc["_id"] = str(doc["_id"])
    doc["userId"] = str(doc["userId"])
    return doc


@router.put("", response_model=FinancialProfileResponse)
def update_profile(
    payload: FinancialProfileUpdate,
    current_user: dict = Depends(get_current_user),
):
    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])

    existing = coll.find_one({"userId": user_id})
    if not existing:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Financial profile does not exist yet. Use POST to create.",
        )

    update_dict = {k: v for k, v in payload.model_dump(exclude_unset=True).items() if v is not None}
    if not update_dict:
        existing["_id"] = str(existing["_id"])
        existing["userId"] = str(existing["userId"])
        return existing

    update_dict["updatedAt"] = datetime.now(timezone.utc)
    coll.update_one({"_id": existing["_id"]}, {"$set": update_dict})

    updated = coll.find_one({"_id": existing["_id"]})
    updated["_id"] = str(updated["_id"])
    updated["userId"] = str(updated["userId"])
    return updated
