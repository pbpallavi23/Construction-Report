from __future__ import annotations

import os
from functools import lru_cache
from pathlib import Path

_BACKEND_DIR = Path(__file__).resolve().parents[2]


def _load_dotenv() -> None:
    """Minimal .env loader (no external dependency).

    Only sets a key if it is not already present in the real environment,
    so container / shell variables always win over the file.
    """
    env_path = _BACKEND_DIR / ".env"
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = value


def _as_bool(value: str, default: bool = False) -> bool:
    if value is None:
        return default
    return value.strip().lower() in {"1", "true", "yes", "on"}


def _as_int(value: str, default: int) -> int:
    try:
        return int(value)
    except (TypeError, ValueError):
        return default


def _as_float(value: str, default: float) -> float:
    try:
        return float(value)
    except (TypeError, ValueError):
        return default


def _as_cors(value: str) -> list[str]:
    if value is None or value.strip() == "" or value.strip() == "*":
        return ["*"]
    return [origin.strip() for origin in value.split(",") if origin.strip()]


class Settings:
    """Plain configuration object populated from environment variables."""

    def __init__(self) -> None:
        _load_dotenv()

        self.APP_NAME: str = os.environ.get("APP_NAME", "Baxall Site Assistant API")
        self.APP_ENV: str = os.environ.get("APP_ENV", "local")
        self.DEBUG: bool = _as_bool(os.environ.get("DEBUG"), True)
        self.API_V1_PREFIX: str = os.environ.get("API_V1_PREFIX", "/api/v1")
        self.VERSION: str = os.environ.get("VERSION", "1.0.0")

        self.HOST: str = os.environ.get("HOST", "0.0.0.0")
        self.PORT: int = _as_int(os.environ.get("PORT"), 8000)


        self.PERSISTENCE_BACKEND: str = os.environ.get("PERSISTENCE_BACKEND", "sqlite")

        raw_db = os.environ.get("DATABASE_PATH", "baxall.db")
        db_path = Path(raw_db)
        if not db_path.is_absolute():
            db_path = _BACKEND_DIR / db_path
        self.DATABASE_PATH: str = str(db_path)


        raw_uploads = os.environ.get("UPLOAD_DIR", "uploads")
        upload_path = Path(raw_uploads)
        if not upload_path.is_absolute():
            upload_path = _BACKEND_DIR / upload_path
        self.UPLOAD_DIR: str = str(upload_path)

        self.JWT_SECRET_KEY: str = os.environ.get(
            "JWT_SECRET_KEY",
            "baxall-local-prototype-secret-do-not-use-in-production",
        )
        self.JWT_ALGORITHM: str = os.environ.get("JWT_ALGORITHM", "HS256")
        self.ACCESS_TOKEN_EXPIRE_MINUTES: int = _as_int(
            os.environ.get("ACCESS_TOKEN_EXPIRE_MINUTES"), 720
        )

        self.MOCK_OCR_DELAY: float = _as_float(os.environ.get("MOCK_OCR_DELAY"), 1.6)
        self.MOCK_AI_DELAY: float = _as_float(os.environ.get("MOCK_AI_DELAY"), 1.4)








        self.STT_MODEL_SIZE: str = os.environ.get("STT_MODEL_SIZE", "base")
        self.STT_DEVICE: str = os.environ.get("STT_DEVICE", "cpu")

        self.STT_COMPUTE_TYPE: str = os.environ.get("STT_COMPUTE_TYPE", "int8")
        self.STT_LANGUAGE: str = os.environ.get("STT_LANGUAGE", "en")
        raw_stt_cache = os.environ.get("STT_MODEL_CACHE_DIR", ".cache/whisper")
        stt_cache_path = Path(raw_stt_cache)
        if not stt_cache_path.is_absolute():
            stt_cache_path = _BACKEND_DIR / stt_cache_path
        self.STT_MODEL_CACHE_DIR: str = str(stt_cache_path)

        self.CORS_ORIGINS: list[str] = _as_cors(os.environ.get("CORS_ORIGINS", "*"))










        self.AI_AUTOFILL_ENABLED: bool = _as_bool(
            os.environ.get("AI_AUTOFILL_ENABLED"), True
        )
        self.OLLAMA_BASE_URL: str = os.environ.get(
            "OLLAMA_BASE_URL", "http://localhost:11434"
        )
        self.OLLAMA_VISION_MODEL: str = os.environ.get(
            "OLLAMA_VISION_MODEL", "llava"
        )
        self.OLLAMA_TEXT_MODEL: str = os.environ.get(
            "OLLAMA_TEXT_MODEL", "llama3.2"
        )
        self.OLLAMA_TIMEOUT_SECONDS: int = _as_int(
            os.environ.get("OLLAMA_TIMEOUT_SECONDS"), 90
        )


        self.AI_AUTOFILL_MAX_PICTURES: int = _as_int(
            os.environ.get("AI_AUTOFILL_MAX_PICTURES"), 6
        )
        self.AI_AUTOFILL_MAX_NOTES: int = _as_int(
            os.environ.get("AI_AUTOFILL_MAX_NOTES"), 8
        )


@lru_cache
def get_settings() -> Settings:
    return Settings()


settings = get_settings()
