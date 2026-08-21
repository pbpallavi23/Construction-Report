from __future__ import annotations

from typing import Any

from app.core.exceptions import ConflictError, NotFoundError, ValidationAppError
from app.core.security import hash_password
from app.core.utils import new_id
from app.persistence import repositories

_EDITABLE_FIELDS = ("full_name", "phone", "avatar_url")


def list_assistants() -> list[dict[str, Any]]:
    return repositories.assistants.list()


def create_assistant(
    full_name: str,
    email: str,
    password: str,
    role: str | None = None,
    phone: str | None = None,
) -> dict[str, Any]:
    full_name = (full_name or "").strip()
    email = (email or "").strip().lower()
    if not full_name or not email or not password:
        raise ValidationAppError("Name, email and password are required.")
    if repositories.assistants.find_by_email(email) is not None:
        raise ConflictError(f"A user with email '{email}' already exists.")
    record = {
        "assistant_id": new_id("user"),
        "full_name": full_name,
        "email": email,
        "password_hash": hash_password(password),
        "role": (role or "").strip() or None,
        "phone": (phone or "").strip() or None,
        "avatar_url": None,
    }
    return repositories.assistants.add(record)


def delete_assistant(assistant_id: str) -> None:
    if not repositories.assistants.delete(assistant_id):
        raise NotFoundError(f"User '{assistant_id}' was not found.")


def get_assistant(assistant_id: str) -> dict[str, Any]:
    row = repositories.assistants.get(assistant_id)
    if row is None:
        raise NotFoundError(f"Assistant '{assistant_id}' was not found.")
    return row


def update_profile(assistant_id: str, changes: dict[str, Any]) -> dict[str, Any]:
    updates = {
        key: value
        for key, value in changes.items()
        if key in _EDITABLE_FIELDS and value is not None
    }
    row = repositories.assistants.update(assistant_id, updates)
    if row is None:
        raise NotFoundError(f"Assistant '{assistant_id}' was not found.")
    return row
