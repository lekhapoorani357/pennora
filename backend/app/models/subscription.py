from sqlalchemy import Column, String, Float, Boolean, DateTime
from app.models.base import Base, generate_id, utc_now


class Subscription(Base):
    __tablename__ = "subscriptions"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=False)
    tier = Column(String(50), default="free", nullable=False)  # "free" | "premium"
    status = Column(String(50), default="active", nullable=False)  # "active" | "cancelled" | "expired"
    price = Column(Float, default=99.0, nullable=False)
    currency = Column(String(10), default="INR", nullable=False)
    billingCycle = Column(String(20), default="monthly", nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    startDate = Column(DateTime, default=utc_now, nullable=False)
    endDate = Column(DateTime, nullable=True)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    def to_dict(self):
        return {
            "_id": str(self.id),
            "userId": str(self.userId),
            "tier": self.tier,
            "status": self.status,
            "price": self.price,
            "currency": self.currency,
            "billingCycle": self.billingCycle,
            "isDemo": self.isDemo,
            "startDate": self.startDate,
            "endDate": self.endDate,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
