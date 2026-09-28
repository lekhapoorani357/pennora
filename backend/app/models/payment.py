from sqlalchemy import Column, String, Float, Boolean, DateTime
from app.models.base import Base, generate_id, utc_now


class Payment(Base):
    __tablename__ = "payments"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=False)
    subscriptionId = Column(String(36), index=True, nullable=True)
    amount = Column(Float, nullable=False)  # Gross amount
    currency = Column(String(10), default="INR", nullable=False)
    orderId = Column(String(100), index=True, nullable=True)  # Gateway order ID
    planCode = Column(String(50), nullable=True)  # Plan purchased
    paymentMethod = Column(String(50), default="demo", nullable=False)
    gatewayRef = Column(String(100), nullable=True)  # Gateway payment reference
    status = Column(String(50), default="pending", nullable=False)  # "pending", "paid", "failed", "refunded"
    taxAmount = Column(Float, default=0.0, nullable=False)
    netAmount = Column(Float, default=0.0, nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    # Snake-case aliases
    @property
    def user_id(self):
        return self.userId

    @property
    def subscription_id(self):
        return self.subscriptionId

    @property
    def order_id(self):
        return self.orderId

    @property
    def plan_code(self):
        return self.planCode

    @property
    def payment_method(self):
        return self.paymentMethod

    @property
    def gateway_ref(self):
        return self.gatewayRef

    @property
    def tax_amount(self):
        return self.taxAmount

    @property
    def net_amount(self):
        return self.netAmount

    @property
    def is_demo(self):
        return self.isDemo

    def to_dict(self):
        return {
            "_id": str(self.id),
            "userId": str(self.userId),
            "subscriptionId": str(self.subscriptionId) if self.subscriptionId else None,
            "orderId": self.orderId,
            "planCode": self.planCode,
            "paymentMethod": self.paymentMethod,
            "amount": self.amount,
            "currency": self.currency,
            "gatewayRef": self.gatewayRef,
            "status": self.status,
            "taxAmount": self.taxAmount,
            "netAmount": self.netAmount,
            "isDemo": self.isDemo,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
