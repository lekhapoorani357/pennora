from sqlalchemy import Column, String, Boolean, DateTime, Text
from app.models.base import Base, generate_id, utc_now


class AnalyticsEvent(Base):
    __tablename__ = "analytics_events"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    userId = Column(String(36), index=True, nullable=True)
    eventName = Column(String(100), index=True, nullable=False)
    properties = Column(Text, nullable=True)  # JSON string with non-sensitive event properties
    isDemo = Column(Boolean, default=False, nullable=False)
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
            "eventName": self.eventName,
            "properties": self.properties,
            "isDemo": self.isDemo,
            "createdAt": self.createdAt,
        }
