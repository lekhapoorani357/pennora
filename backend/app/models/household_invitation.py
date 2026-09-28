from sqlalchemy import Column, String, DateTime
from app.models.base import Base, generate_id, utc_now


class HouseholdInvitation(Base):
    __tablename__ = "household_invitations"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    householdId = Column(String(36), index=True, nullable=False)
    invitedByUserId = Column(String(36), index=True, nullable=False)
    inviteeEmail = Column(String(150), index=True, nullable=False)
    inviteeUserId = Column(String(36), index=True, nullable=True)
    status = Column(String(30), default="pending", nullable=False)  # "pending", "accepted", "declined", "revoked"
    inviteCode = Column(String(50), unique=True, nullable=False)
    expiresAt = Column(DateTime, nullable=False)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
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
    def invited_by_user_id(self):
        return self.invitedByUserId

    @property
    def invitee_email(self):
        return self.inviteeEmail

    @property
    def invite_code(self):
        return self.inviteCode

    @property
    def expires_at(self):
        return self.expiresAt

    def to_dict(self):
        return {
            "_id": str(self.id),
            "householdId": str(self.householdId),
            "invitedByUserId": str(self.invitedByUserId),
            "inviteeEmail": self.inviteeEmail,
            "inviteeUserId": str(self.inviteeUserId) if self.inviteeUserId else None,
            "status": self.status,
            "inviteCode": self.inviteCode,
            "expiresAt": self.expiresAt,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
