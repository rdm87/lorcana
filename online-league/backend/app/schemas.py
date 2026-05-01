from datetime import datetime
from pydantic import BaseModel, Field, HttpUrl, model_validator

class UserOut(BaseModel):
    id: int
    discord_id: str
    username: str
    avatar_url: str | None
    is_admin: bool
    class Config:
        from_attributes = True

class PrizeShare(BaseModel):
    position: int = Field(ge=1)
    percentage: float = Field(gt=0, le=100)

class TournamentCreate(BaseModel):
    title: str = Field(min_length=3, max_length=180)
    cap: int = Field(gt=0, le=1024)
    entry_fee_eur: float = Field(ge=0)
    paypal_link: HttpUrl
    start_date: datetime
    end_date: datetime
    rules_description: str = Field(min_length=1)
    prize_players_count: int = Field(gt=0)
    prize_distribution: list[PrizeShare]

    @model_validator(mode="after")
    def validate_business_rules(self):
        if self.end_date <= self.start_date:
            raise ValueError("La data di fine deve essere successiva alla data di inizio")
        if self.prize_players_count != len(self.prize_distribution):
            raise ValueError("Il numero di giocatori a premio deve coincidere con la distribuzione")
        total = round(sum(p.percentage for p in self.prize_distribution), 2)
        if total != 100:
            raise ValueError("La somma delle percentuali del montepremi deve essere 100")
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
    prize_players_count: int
    prize_distribution: list[PrizeShare]
    registered_count: int
    class Config:
        from_attributes = True

class RegistrationOut(BaseModel):
    id: int
    tournament_id: int
    user_id: int
    paid: bool
    created_at: datetime
    class Config:
        from_attributes = True

class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"
