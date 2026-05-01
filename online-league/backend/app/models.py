from datetime import date as _date_type, datetime, timezone
from sqlalchemy import Boolean, Date, DateTime, Float, ForeignKey, Integer, String, Text, UniqueConstraint
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
    in_server: Mapped[bool] = mapped_column(Boolean, default=False)
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
    prize_players_count: Mapped[int] = mapped_column(Integer, default=0)
    prize_distribution: Mapped[str] = mapped_column(Text, default="[]")
    prize_rule: Mapped[str | None] = mapped_column(Text, nullable=True)
    status: Mapped[str] = mapped_column(String(20), default="registration")
    created_by_id: Mapped[int] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    registrations = relationship("Registration", back_populates="tournament", cascade="all, delete-orphan")
    matches = relationship("Match", back_populates="tournament", cascade="all, delete-orphan")

class Registration(Base):
    __tablename__ = "registrations"
    __table_args__ = (UniqueConstraint("tournament_id", "user_id", name="uq_registration"),)
    id: Mapped[int] = mapped_column(primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"))
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"), nullable=True)
    discord_account: Mapped[str] = mapped_column(String(120))
    first_name: Mapped[str] = mapped_column(String(120))
    last_name: Mapped[str] = mapped_column(String(120))
    paid: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    tournament = relationship("Tournament", back_populates="registrations")
    user = relationship("User")

class BotConfig(Base):
    __tablename__ = "bot_config"
    id: Mapped[int] = mapped_column(primary_key=True, default=1)
    guild_id: Mapped[str | None] = mapped_column(String(32), nullable=True)
    bot_token: Mapped[str | None] = mapped_column(String(200), nullable=True)
    invite_channel_id: Mapped[str | None] = mapped_column(String(32), nullable=True)
    invite_url: Mapped[str | None] = mapped_column(String(200), nullable=True)
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)

class Availability(Base):
    __tablename__ = "availabilities"
    id: Mapped[int] = mapped_column(primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id", ondelete="CASCADE"))
    reg_id: Mapped[int] = mapped_column(ForeignKey("registrations.id", ondelete="CASCADE"))
    slot_date: Mapped[_date_type] = mapped_column(Date)
    time_start: Mapped[str] = mapped_column(String(5))
    time_end: Mapped[str] = mapped_column(String(5))
    registration = relationship("Registration")

class Match(Base):
    __tablename__ = "matches"
    id: Mapped[int] = mapped_column(primary_key=True)
    tournament_id: Mapped[int] = mapped_column(ForeignKey("tournaments.id"))
    reg1_id: Mapped[int] = mapped_column(ForeignKey("registrations.id"))
    reg2_id: Mapped[int] = mapped_column(ForeignKey("registrations.id"))
    # games won by each player (e.g. 2-1 means reg1 wins 2 games, reg2 wins 1)
    games_reg1: Mapped[int | None] = mapped_column(Integer, nullable=True)
    games_reg2: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # who proposed the result (registration id)
    proposed_by_reg_id: Mapped[int | None] = mapped_column(Integer, nullable=True)
    # pending | confirmed
    result_status: Mapped[str] = mapped_column(String(20), default="pending")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=_utcnow)
    tournament = relationship("Tournament", back_populates="matches")
    reg1 = relationship("Registration", foreign_keys=[reg1_id])
    reg2 = relationship("Registration", foreign_keys=[reg2_id])
