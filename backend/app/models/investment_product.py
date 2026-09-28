from sqlalchemy import Column, String, Float, Integer, Boolean, DateTime, Text
from app.models.base import Base, generate_id, utc_now


class InvestmentProduct(Base):
    __tablename__ = "investment_products"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    name = Column(String(150), nullable=False)
    category = Column(String(50), nullable=False)  # FD, RD, GOV_SAVINGS, PPF, MUTUAL_FUNDS, INDEX_FUNDS, EQUITY
    minTenureMonths = Column(Integer, default=6, nullable=False)
    maxTenureMonths = Column(Integer, default=120, nullable=False)
    minAmount = Column(Float, default=500.0, nullable=False)
    assumedAnnualRateMin = Column(Float, nullable=False)
    assumedAnnualRateMax = Column(Float, nullable=False)
    risk = Column(String(50), default="Moderate", nullable=False)  # Low, Moderate, High, Very High
    liquidity = Column(String(50), default="Moderate", nullable=False)  # High, Moderate, Lock-in
    taxNotes = Column(Text, nullable=True)
    isGuaranteed = Column(Boolean, default=False, nullable=False)
    source = Column(String(150), default="Illustrative assumptions for demonstration", nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    description = Column(Text, nullable=True)
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
            "name": self.name,
            "category": self.category,
            "minTenureMonths": self.minTenureMonths,
            "maxTenureMonths": self.maxTenureMonths,
            "minAmount": self.minAmount,
            "assumedAnnualRateMin": self.assumedAnnualRateMin,
            "assumedAnnualRateMax": self.assumedAnnualRateMax,
            "risk": self.risk,
            "liquidity": self.liquidity,
            "taxNotes": self.taxNotes,
            "isGuaranteed": self.isGuaranteed,
            "source": self.source,
            "isDemo": self.isDemo,
            "description": self.description,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
