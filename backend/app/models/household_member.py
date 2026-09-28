from sqlalchemy import Column, String, Boolean, DateTime
from app.models.base import Base, generate_id, utc_now


class HouseholdMember(Base):
    __tablename__ = "household_members"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    householdId = Column(String(36), index=True, nullable=False)
    userId = Column(String(36), index=True, nullable=False)
    role = Column(String(30), default="member", nullable=False)  # "owner" | "member"
    status = Column(String(30), default="active", nullable=False)  # "active" | "removed" | "left"
    shareFinancials = Column(Boolean, default=False, nullable=False)  # Strict privacy by default
    joinedAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    @property
    def household_id(self):
        return self.householdId

    @property
    def user_id(self):
        return self.userId

    @property
    def share_financials(self):
        return self.shareFinancials

    def to_dict(self):
        return {
            "_id": str(self.id),
            "householdId": str(self.householdId),
            "userId": str(self.userId),
            "role": self.role,
            "status": self.status,
            "shareFinancials": self.shareFinancials,
            "joinedAt": self.joinedAt,
            "updatedAt": self.updatedAt,
        }
