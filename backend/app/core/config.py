"""
OpenVAL Core Configuration
All settings are read from environment variables.
Never hardcode secrets. Use .env for local development only.
"""

from functools import lru_cache
from typing import List, Optional
from pydantic import AnyHttpUrl, EmailStr, field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
    )

    # ── Application ──────────────────────────────────────────
    APP_NAME: str = "OpenVAL"
    APP_VERSION: str = "0.1.0"
    APP_ENV: str = "production"          # production | staging | development
    DEBUG: bool = False
    SITE_URL: str = "https://openval.example.com"
    ALLOWED_HOSTS: List[str] = ["*"]

    @field_validator("ALLOWED_HOSTS", mode="before")
    @classmethod
    def parse_allowed_hosts(cls, v):
        if isinstance(v, str):
            return [h.strip() for h in v.split(",")]
        return v

    # ── Database ─────────────────────────────────────────────
    DATABASE_URL: str = "postgresql+asyncpg://openval:changeme@localhost/openval"
    DATABASE_POOL_SIZE: int = 20
    DATABASE_MAX_OVERFLOW: int = 40
    DATABASE_POOL_TIMEOUT: int = 30
    DATABASE_ECHO: bool = False          # Set True to log all SQL (dev only)

    # ── Redis ────────────────────────────────