from __future__ import annotations

from typing import Any

from app.core.config import settings
from app.core.exceptions import UnauthorizedError
from app.core.security import create_access_token, verify_password
from app.persistence import repositories


def authenticate(email: str, password: str) -> dict[str, Any]:
    assistant = repositories.assistants.find_by_email(email)
    if assistant is None or not verify_password(password, assistant["password_hash"]):
        raise UnauthorizedError("Invalid email or password.")
    return assistant


def issue_token(assistant: dict[str, Any]) -> dict[str, Any]:
    token = create_access_token(
        subject=assistant["assistant_id"],
        claims={"email": assistant["email"], "role": assistant.get("role")},
    )
    return {
        "access_token": token,
        "token_type": "bearer",
        "expires_in": settings.ACCESS_TOKEN_EXPIRE_MINUTES * 60,
        "assistant": assistant,
    }


def get_assistant_by_id(assistant_id: str) -> dict[str, Any] | None:
    return repositories.assistants.get(assistant_id)
