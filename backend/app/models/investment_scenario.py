from sqlalchemy import Column, String, Float, Integer, DateTime, Text
from app.models.base import Base, generate_id, utc_now


class InvestmentScenario(Base):
    __tablename__ = "investment_scenarios"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=False)
    initialAmount = Column(Float, nullable=False)
    monthlyContribution = Column(Float, default=0.0, nullable=False)
    tenureMonths = Column(Integer, nullable=False)
    selectedProductIds = Column(Text, nullable=True)  # JSON list
    results = Column(Text, nullable=False)  # JSON text with scenarios & goal impact
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
            "userId": str(self.userId),
            "initialAmount": self.initialAmount,
            "monthlyContribution": self.monthlyContribution,
            "tenureMonths": self.tenureMonths,
            "selectedProductIds": self.selectedProductIds,
            "results": self.results,
            "createdAt": self.createdAt,
        }
