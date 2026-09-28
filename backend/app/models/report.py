from sqlalchemy import Column, String, Boolean, DateTime, Text
from app.models.base import Base, generate_id, utc_now


class FinancialReport(Base):
    __tablename__ = "financial_reports"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=False)
    reportType = Column(String(50), default="financial_health_growth", nullable=False)
    status = Column(String(50), default="pending", nullable=False)  # "pending", "completed", "failed"
    pdfBytes = Column(Text, nullable=True)  # Base64 encoded PDF payload
    purchaseId = Column(String(36), index=True, nullable=True)
    isDemo = Column(Boolean, default=True, nullable=False)
    summaryJson = Column(Text, nullable=True)  # Serialized metrics summary
    generatedAt = Column(DateTime, nullable=True)
    asOfDate = Column(DateTime, default=utc_now, nullable=False)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    @property
    def user_id(self):
        return self.userId

    @property
    def report_type(self):
        return self.reportType

    @property
    def pdf_bytes(self):
        return self.pdfBytes

    @property
    def purchase_id(self):
        return self.purchaseId

    @property
    def is_demo(self):
        return self.isDemo

    @property
    def summary_json(self):
        return self.summaryJson

    def to_dict(self):
        return {
            "_id": str(self.id),
            "userId": str(self.userId),
            "reportType": self.reportType,
            "status": self.status,
            "hasPdf": bool(self.pdfBytes),
            "purchaseId": self.purchaseId,
            "isDemo": self.isDemo,
            "summaryJson": self.summaryJson,
            "generatedAt": self.generatedAt.isoformat() if self.generatedAt else None,
            "asOfDate": self.asOfDate.isoformat() if self.asOfDate else None,
            "createdAt": self.createdAt.isoformat() if self.createdAt else None,
            "updatedAt": self.updatedAt.isoformat() if self.updatedAt else None,
        }
