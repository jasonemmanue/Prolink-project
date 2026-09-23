from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "ProLink API"
    environment: str = "dev"

    database_url: str = "postgresql+psycopg2://prolink:prolink@localhost:5432/prolink"
    redis_url: str = "redis://localhost:6379/0"

    jwt_secret: str = "change-me-in-prod"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60
    refresh_token_ttl_days: int = 30

    cinetpay_api_key: str = ""
    cinetpay_site_id: str = ""

    livekit_url: str = ""
    livekit_api_key: str = ""
    livekit_api_secret: str = ""

    firebase_project_id: str = ""

    translation_provider: str = "libretranslate"  # libretranslate | deepl | google
    translation_base_url: str = "https://libretranslate.de"

    cors_origins: list[str] = ["http://localhost:3000", "*"]


settings = Settings()
