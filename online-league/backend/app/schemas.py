from datetime import date as _date_type, datetime
from pydantic import BaseModel, Field, model_validator

class UserOut(BaseModel):
    id: int
    discord_id: str
    username: str
    avatar_url: str | None
    is_admin: bool
    in_server: bool = False
    class Config:
        from_attributes = True

class BotConfigIn(BaseModel):
    guild_id: str | None = None
    bot_token: str | None = None
    invite_channel_id: str | None = None
    invite_url: str | None = None

class BotConfigOut(BaseModel):
    guild_id: str | None
    invite_channel_id: str | None
    invite_url: str | None
    has_token: bool

class PrizeOut(BaseModel):
    position: int
    prize_eur: float

class TournamentCreate(BaseModel):
    title: str = Field(min_length=3, max_length=180)
    cap: int = Field(gt=0, le=1024)
    entry_fee_eur: float = Field(ge=0)
    paypal_link: str | None = None
    start_date: datetime
    end_date: datetime
    rules_description: str = Field(min_length=1)
    prize_rule: str | None = None

    @model_validator(mode="after")
    def validate_business_rules(self):
        if self.end_date <= self.start_date:
            raise ValueError("La data di fine deve essere successiva alla data di inizio")
        if self.entry_fee_eur > 0 and not self.paypal_link:
            raise ValueError("Il link PayPal è obbligatorio per i tornei a pagamento")
        if self.paypal_link and not self.paypal_link.startswith("http"):
            raise ValueError("Il link PayPal deve essere un URL valido (deve iniziare con http)")
        if self.prize_rule is not None:
            try:
                values = [float(x.strip()) for x in self.prize_rule.split(',')]
                if not values or any(v <= 0 for v in values):
                    raise ValueError()
            except Exception:
                raise ValueError(
                    "prize_rule non valido. Inserisci percentuali positive separate da virgola, es: '40,25,35'"
                )
        return self

class TournamentOut(BaseModel):
    id: int
    title: str
    cap: int
    entry_fee_eur: float
    paypal_link: str
    start_date: datetime
    end_date: datetime
    rules_description: str
    prize_rule: str | None
    prizes: list[PrizeOut]
    registered_count: int
    status: str
    class Config:
        from_attributes = True

class RegistrationCreate(BaseModel):
    discord_account: str = Field(min_length=2, max_length=120)
    first_name: str = Field(min_length=1, max_length=120)
    last_name: str = Field(min_length=1, max_length=120)

class RegistrationOut(BaseModel):
    id: int
    tournament_id: int
    user_id: int | None
    discord_account: str
    first_name: str
    last_name: str
    paid: bool
    created_at: datetime
    class Config:
        from_attributes = True

class PublicRegistrationOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    created_at: datetime
    class Config:
        from_attributes = True

class TournamentDetailOut(TournamentOut):
    registrations: list[PublicRegistrationOut]
    admin_registrations: list[RegistrationOut] | None = None
    my_registration: RegistrationOut | None = None

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"

class ResultPropose(BaseModel):
    games_reg1: int = Field(ge=0, le=2)
    games_reg2: int = Field(ge=0, le=2)

    @model_validator(mode="after")
    def validate_result(self):
        g1, g2 = self.games_reg1, self.games_reg2
        valid = {(2, 0), (2, 1), (1, 0), (1, 1), (0, 2), (1, 2), (0, 1)}
        if (g1, g2) not in valid:
            raise ValueError("Risultato non valido. Valori ammessi: 2-0, 2-1, 1-0, 1-1 e inversi")
        return self

class MatchPlayerOut(BaseModel):
    id: int
    first_name: str
    last_name: str
    class Config:
        from_attributes = True

class MatchOut(BaseModel):
    id: int
    tournament_id: int
    reg1_id: int
    reg2_id: int
    reg1: MatchPlayerOut
    reg2: MatchPlayerOut
    games_reg1: int | None
    games_reg2: int | None
    proposed_by_reg_id: int | None
    result_status: str

class StandingEntry(BaseModel):
    reg_id: int
    first_name: str
    last_name: str
    played: int
    wins: int
    draws: int
    losses: int
    points: int
    games_won: int
    games_lost: int

class TestTournamentCreate(BaseModel):
    player_count: int = Field(ge=2, le=50)
    entry_fee_eur: float = Field(ge=0, default=0)

class AvailabilitySlotIn(BaseModel):
    slot_date: _date_type
    time_start: str = Field(pattern=r"^\d{2}:\d{2}$")
    time_end: str = Field(pattern=r"^\d{2}:\d{2}$")

class AvailabilitySlotOut(BaseModel):
    id: int
    slot_date: _date_type
    time_start: str
    time_end: str
    class Config:
        from_attributes = True

class PlayerAvailabilityOut(BaseModel):
    reg_id: int
    first_name: str
    last_name: str
    slots: list[AvailabilitySlotOut]

class AvailabilityUpdate(BaseModel):
    slots: list[AvailabilitySlotIn]
