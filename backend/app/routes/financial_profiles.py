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
profile_router = APIRouter(prefix="/profile", tags=["Profile"])


def _handle_set_role(payload: RoleSelectionRequest, current_user: dict):
    valid_roles = ["student", "working_single", "working_married", "professional", "family"]
    role = payload.role.strip().lower()
    if role not in valid_roles:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=f"Role must be one of {valid_roles}",
        )

    # Normalize aliases if desired
    normalized_role = role
    if role == "professional":
        normalized_role = "working_single"
    elif role == "family":
        normalized_role = "working_married"

    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])
    now = datetime.now(timezone.utc)

    existing = coll.find_one({"userId": user_id})
    if existing:
        coll.update_one({"_id": existing["_id"]}, {"$set": {"financialRole": normalized_role, "updatedAt": now}})
        updated = coll.find_one({"_id": existing["_id"]})
        updated["_id"] = str(updated["_id"])
        updated["userId"] = str(updated["userId"])
        return updated

    default_occupation = "Student" if normalized_role == "student" else "Professional"
    doc = {
        "userId": user_id,
        "financialRole": normalized_role,
        "roleData": None,
        "age": 20 if normalized_role == "student" else 28,
        "occupation": default_occupation,
        "dependents": 2 if normalized_role == "working_married" else 0,
        "monthlyIncome": 0.0,
        "incomeType": "Pocket Money/Stipend" if normalized_role == "student" else "Salary",
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


def _handle_get_role(current_user: dict):
    coll = get_collection("financial_profiles")
    user_id = str(current_user["_id"])
    doc = coll.find_one({"userId": user_id})
    role = doc.get("financialRole", "working_single") if doc else "working_single"
    return {"role": role, "financialRole": role}


@router.post("/role", response_model=FinancialProfileResponse, summary="Select or update user's financial role")
def set_financial_role(
    payload: RoleSelectionRequest,
    current_user: dict = Depends(get_current_user),
):
    return _handle_set_role(payload, current_user)


@router.get("/role", summary="Get user's current financial role")
def get_financial_role(current_user: dict = Depends(get_current_user)):
    return _handle_get_role(current_user)


@profile_router.post("/role", response_model=FinancialProfileResponse, summary="Select or update user's financial role")
def set_profile_role(
    payload: RoleSelectionRequest,
    current_user: dict = Depends(get_current_user),
):
    return _handle_set_role(payload, current_user)


@profile_router.get("/role", summary="Get user's current financial role")
def get_profile_role(current_user: dict = Depends(get_current_user)):
    return _handle_get_role(current_user)


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
