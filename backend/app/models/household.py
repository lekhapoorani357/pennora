from sqlalchemy import Column, String, Integer, Boolean, DateTime
from app.config import settings
from app.models.base import Base, generate_id, utc_now


class Household(Base):
    __tablename__ = "households"

    id = Column("_id", String(36), primary_key=True, default=generate_id)
    name = Column(String(100), default="My Family Household", nullable=False)
    ownerId = Column(String(36), index=True, nullable=False)
    maxMembers = Column(Integer, default=settings.FAMILY_MAX_MEMBERS, nullable=False)
    isDemo = Column(Boolean, default=True, nullable=False)
    createdAt = Column(DateTime, default=utc_now, nullable=False)
    updatedAt = Column(DateTime, default=utc_now, onupdate=utc_now, nullable=False)

    @property
    def _id(self):
        return self.id

    @_id.setter
    def _id(self, val):
        self.id = val

    @property
    def owner_id(self):
        return self.ownerId

    @property
    def max_members(self):
        return self.maxMembers

    @property
    def is_demo(self):
        return self.isDemo

    def to_dict(self):
        return {
            "_id": str(self.id),
            "name": self.name,
            "ownerId": str(self.ownerId),
            "maxMembers": self.maxMembers,
            "isDemo": self.isDemo,
            "createdAt": self.createdAt,
            "updatedAt": self.updatedAt,
        }
