from datetime import datetime, timezone
from sqlalchemy import Boolean, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .db import Base

def _utcnow() -> datetime:
    return datetime.now(timezone.utc).replace(tzinfo=None)

class User(Base):
    __tablename__ = "users"
    id: Mapped[int] = mapped_column(primary_key=True)
    discord_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    username: Mapped[str] = mapped_column(String(120))
    avatar_url: Mapped[str | None] = mapped_column(String(500), nullable=True)
    is_admin: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

class Tournament(Base):
    __tablename__ = "tournaments"
    id: Mapped[int] = mapped_column(primary_key=True)
    title: Mapped[str] = mapped_column(String(180))
    cap: Mapped[int] = mapped_column(Integer)
    entry_fee_eur: Mapped[float] = mapped_column(Float, default=0)
    paypal_link: Mapped[str] = mapped_column(String(600))
    start_date: Mapped[datetime] = mapped_column(DateTime)
    end_date: Mapped[datetime] = mapped_column(DateTime)
    rules_description: Mapped[str] = mapped_column(Text)
    prize_players_count: Mapped[int] = mapped_column(Integer)
    prize_distribution: Mapped[str] = mapped_column(Text, default="[]")
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    registrations = relationship("Registration", back_populates="tournament", cascade="all, delete-orphan")

class Registration(Base):
    __tablename__ = "registrations"
    __table_args__ = (UniqueConstraint("tournament_id", "user_id", name="uq_registration"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"))
    user_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    discord_account: Mapped[str] = mapped_column(String(120))
    first_name: Mapped[str] = mapped_column(String(120))
    last_name: Mapped[str] = mapped_column(String(120))
    paid: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    tournament = relationship("Tournament", back_populates="registrations")
    user = relationship("User")
