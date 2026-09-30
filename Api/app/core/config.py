from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    app_name: str = "ProLink API"
    environment: str = "dev"

    database_url: str = "postgresql+psycopg2://prolink:prolink@localhost:5432/prolink"

    jwt_secret: str = "change-me-in-prod"
    jwt_algorithm: str = "HS256"
    access_token_ttl_minutes: int = 60
    refresh_token_ttl_days: int = 30

    # Règles produit (valeurs par défaut, surchargées par la table platform_settings).
    commission_service_pct: float = 10.0
    commission_live_pct: float = 15.0
    commission_tip_pct: float = 10.0
    wallet_min_balance_xaf: int = 500
    withdraw_min_xaf: int = 1000
    two_fa_monthly_threshold_xaf: int = 100_000
    auto_release_hours: int = 72

    # OTP : en dev le code est renvoyé dans la réponse (aucun SMS réel).
    otp_ttl_minutes: int = 10
    otp_dev_echo: bool = True

    cinetpay_api_key: str = ""
    cinetpay_site_id: str = ""

    livekit_url: str = ""
    livekit_api_key: str = ""
    livekit_api_secret: str = ""

    firebase_project_id: str = ""

    translation_provider: str = "libretranslate"  # libretranslate | deepl | google
    translation_base_url: str = "https://libretranslate.de"

    cors_origins: list[str] = ["http://localhost:3000", "*"]

    seed_demo: bool = True

    @property
    def payments_sandbox(self) -> bool:
        """Sans clés CinetPay, les paiements sont simulés et confirmés d'office."""
        return not (self.cinetpay_api_key and self.cinetpay_site_id)


settings = Settings()
