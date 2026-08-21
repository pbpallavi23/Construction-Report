from __future__ import annotations

from typing import Any

from flask import Response, jsonify, request

from app.core.exceptions import ValidationAppError

_SENSITIVE_KEYS = {"password_hash"}


def public(value: Any) -> Any:
    """Recursively strip sensitive keys (e.g. password_hash) from output."""
    if isinstance(value, dict):
        return {k: public(v) for k, v in value.items() if k not in _SENSITIVE_KEYS}
    if isinstance(value, list):
        return [public(item) for item in value]
    return value


def json_ok(data: Any, status: int = 200) -> Response:
    response = jsonify(public(data))
    response.status_code = status
    return response


def body() -> dict[str, Any]:
    """Return the JSON request body as a dict (empty dict when absent)."""
    data = request.get_json(silent=True)
    if data is None:
        return {}
    if not isinstance(data, dict):
        raise ValidationAppError("Request body must be a JSON object.")
    return data


def require_fields(data: dict[str, Any], *fields: str) -> None:
    missing = [f for f in fields if data.get(f) in (None, "")]
    if missing:
        raise ValidationAppError(
            "Missing required field(s): " + ", ".join(missing),
            details={"missing": missing},
        )
