from sqlalchemy import Column, String, Float, Boolean, DateTime
from app.models.base import Base, generate_id, utc_now


class RevenueEvent(Base):
    __tablename__ = "revenue_events"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=True)
    revenueSource = Column(String(50), nullable=False)  # SUBSCRIPTION, ADVERTISEMENT, PARTNER_REFERRAL, PREMIUM_FEATURE, OTHER
    eventType = Column(String(50), nullable=False)
    amount = Column(Float, nullable=False)  # Gross amount
    taxAmount = Column(Float, default=0.0, nullable=False)
    netRevenue = Column(Float, nullable=False)
    currency = Column(String(10), default="INR", nullable=False)
    partnerId = Column(String(50), nullable=True)
    status = Column(String(50), default="COMPLETED", nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    createdAt = Column(DateTime, default=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    def to_dict(self):
        return {
            "_id": str(self.id),
            "userId": str(self.userId) if self.userId else None,
            "revenueSource": self.revenueSource,
            "eventType": self.eventType,
            "amount": self.amount,
            "taxAmount": self.taxAmount,
            "netRevenue": self.netRevenue,
            "currency": self.currency,
            "partnerId": self.partnerId,
            "status": self.status,
            "isDemo": self.isDemo,
            "createdAt": self.createdAt,
        }
