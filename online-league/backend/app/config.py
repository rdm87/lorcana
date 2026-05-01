from functools import lru_cache
from pydantic_settings import BaseSettings

class Settings(BaseSettings):
    app_name: str = "Lorcana Tournament Manager"
    frontend_url: str = "http://localhost:8080"
    backend_url: str = "http://localhost:8000"
    database_url: str = "sqlite:///./lorcana.db"
    jwt_secret: str = "change-me"
    jwt_algorithm: str = "HS256"
    discord_client_id: str = ""
    discord_client_secret: str = ""
    discord_redirect_uri: str = "http://localhost:8000/api/auth/discord/callback"
    admin_discord_ids: str = ""
    allowed_origins: str = "http://localhost:8080,http://localhost:3000"

    @property
    def admin_ids(self) -> set[str]:
        return {x.strip() for x in self.admin_discord_ids.split(',') if x.strip()}

    @property
    def allowed_origins_list(self) -> list[str]:
        return [o.strip() for o in self.allowed_origins.split(',') if o.strip()]

    class Config:
        env_file = ".env"

@lru_cache
def get_settings() -> Settings:
    return Settings()
