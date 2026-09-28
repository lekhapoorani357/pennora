from datetime import datetime
from typing import Optional
from pydantic import BaseModel, Field, ConfigDict


class RoleSelectionRequest(BaseModel):
    role: str = Field(..., description="Role: 'student', 'professional', or 'family'")


class FinancialProfileBase(BaseModel):
    financialRole: Optional[str] = Field("professional", description="'student', 'professional', 'family'")
    roleData: Optional[str] = Field(None, description="JSON string of role-specific onboarding data")
    age: int = Field(22, ge=1, le=120)
    occupation: str = Field("Professional", min_length=1)
    dependents: int = Field(0, ge=0)
    monthlyIncome: float = Field(0.0, ge=0.0)
    incomeType: str = Field("Salary")
    additionalIncome: float = Field(0.0, ge=0.0)
    currentSavings: float = Field(0.0, ge=0.0)
    fixedExpenses: float = Field(0.0, ge=0.0)
    variableExpenses: float = Field(0.0, ge=0.0)
    monthlyEMI: float = Field(0.0, ge=0.0)
    activeLoans: int = Field(0, ge=0)


class FinancialProfileCreate(FinancialProfileBase):
    pass


class FinancialProfileUpdate(BaseModel):
    financialRole: Optional[str] = None
    roleData: Optional[str] = None
    age: Optional[int] = Field(None, ge=1, le=120)
    occupation: Optional[str] = Field(None, min_length=1)
    dependents: Optional[int] = Field(None, ge=0)
    monthlyIncome: Optional[float] = Field(None, ge=0.0)
    incomeType: Optional[str] = None
    additionalIncome: Optional[float] = Field(None, ge=0.0)
    currentSavings: Optional[float] = Field(None, ge=0.0)
    fixedExpenses: Optional[float] = Field(None, ge=0.0)
    variableExpenses: Optional[float] = Field(None, ge=0.0)
    monthlyEMI: Optional[float] = Field(None, ge=0.0)
    activeLoans: Optional[int] = Field(None, ge=0)


class FinancialProfileResponse(FinancialProfileBase):
    id: str = Field(..., alias="_id")
    userId: str
    createdAt: datetime
    updatedAt: datetime

    model_config = ConfigDict(populate_by_name=True)
