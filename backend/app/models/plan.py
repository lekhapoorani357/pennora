from sqlalchemy import Column, String, Float, Boolean, DateTime, Integer, Text
from app.models.base import Base, generate_id, utc_now


class Plan(Base):
    __tablename__ = "plans"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    name = Column(String(100), nullable=False)  # "Free", "Premium", "Student", "Family"
    code = Column(String(50), unique=True, index=True, nullable=False)  # "free", "premium_monthly", "premium_annual", etc.
    tier = Column(String(50), nullable=False)  # "free" | "premium" | "student" | "family"
    billingPeriod = Column(String(20), default="monthly", nullable=False)  # "monthly" | "annual" | "lifetime"
    price = Column(Float, default=0.0, nullable=False)
    currency = Column(String(10), default="INR", nullable=False)
    active = Column(Boolean, default=True, nullable=False)
    trialDays = Column(Integer, default=0, nullable=False)
    featureFlags = Column(Text, nullable=True)  # JSON-encoded array of feature strings
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    # Snake-case property aliases
    @property
    def plan_name(self):
        return self.name

    @property
    def billing_period(self):
        return self.billingPeriod

    @property
    def feature_flags(self):
        return self.featureFlags

    def to_dict(self):
        return {
            "_id": str(self.id),
            "name": self.name,
            "code": self.code,
            "tier": self.tier,
            "billingPeriod": self.billingPeriod,
            "price": self.price,
            "currency": self.currency,
            "active": self.active,
            "trialDays": self.trialDays,
            "featureFlags": self.featureFlags,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
