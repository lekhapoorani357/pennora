from sqlalchemy import Column, String, Float, Boolean, DateTime
from app.models.base import Base, generate_id, utc_now


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=False)
    planId = Column(String(50), nullable=True)  # References Plan code / id
    tier = Column(String(50), default="free", nullable=False)  # "free" | "premium" | "student" | "family"
    status = Column(String(50), default="active", nullable=False)  # "active" | "trialing" | "cancelled" | "expired"
    price = Column(Float, default=99.0, nullable=False)
    currency = Column(String(10), default="INR", nullable=False)
    billingCycle = Column(String(20), default="monthly", nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    startDate = Column(DateTime, default=utc_now, nullable=False)
    endDate = Column(DateTime, nullable=True)
    trialEndsAt = Column(DateTime, nullable=True)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    # Snake-case property aliases for specifications
    @property
    def user_id(self):
        return self.userId

    @property
    def plan_id(self):
        return self.planId

    @property
    def started_at(self):
        return self.startDate

    @property
    def ends_at(self):
        return self.endDate

    @property
    def trial_ends_at(self):
        return self.trialEndsAt

    @property
    def is_demo(self):
        return self.isDemo

    def to_dict(self):
        return {
            "_id": str(self.id),
            "userId": str(self.userId),
            "planId": self.planId,
            "tier": self.tier,
            "status": self.status,
            "price": self.price,
            "currency": self.currency,
            "billingCycle": self.billingCycle,
            "isDemo": self.isDemo,
            "startDate": self.startDate,
            "endDate": self.endDate,
            "trialEndsAt": self.trialEndsAt,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
