from sqlalchemy import Column, String, Float, Boolean, DateTime, Text
from app.models.base import Base, generate_id, utc_now


class PartnerProduct(Base):
    __tablename__ = "partner_products"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    partnerName = Column(String(120), nullable=False)
    productName = Column(String(150), nullable=False)
    category = Column(String(50), nullable=False)  # FD, RD, INSURANCE, MUTUAL_FUND, INVESTMENT, OTHER
    description = Column(Text, nullable=True)
    referralUrl = Column(String(255), nullable=False)
    commissionType = Column(String(50), default="flat", nullable=False)  # flat, percentage
    commissionAmountOrRate = Column(Float, default=0.0, nullable=False)
    active = Column(Boolean, default=True, nullable=False)
    disclosure = Column(Text, nullable=False, default="Partner/referral relationship may result in revenue for Pennora.")
    isDemo = Column(Boolean, default=True, nullable=False)
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
            "partnerName": self.partnerName,
            "productName": self.productName,
            "category": self.category,
            "description": self.description,
            "referralUrl": self.referralUrl,
            "commissionType": self.commissionType,
            "commissionAmountOrRate": self.commissionAmountOrRate,
            "active": self.active,
            "disclosure": self.disclosure,
            "isDemo": self.isDemo,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
