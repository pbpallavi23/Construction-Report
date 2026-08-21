from __future__ import annotations

from functools import wraps
from typing import Any, Callable

from flask import g, request

from app.core.exceptions import UnauthorizedError
from app.core.security import decode_access_token
from app.services import auth_service


def _authenticate_request() -> dict[str, Any]:
    header = request.headers.get("Authorization", "")
    scheme, _, token = header.partition(" ")
    if scheme.lower() != "bearer" or not token.strip():
        raise UnauthorizedError("Authentication required. Provide a bearer token.")

    payload = decode_access_token(token.strip())
    assistant_id = payload.get("sub")
    assistant = auth_service.get_assistant_by_id(assistant_id) if assistant_id else None
    if assistant is None:
        raise UnauthorizedError("Session is no longer valid.")
    return assistant


def require_auth(view: Callable) -> Callable:
    """Decorator that authenticates the request and exposes the current
    assistant via `current_assistant()` / `flask.g.current_assistant`."""

    @wraps(view)
    def wrapper(*args: Any, **kwargs: Any):
        g.current_assistant = _authenticate_request()
        return view(*args, **kwargs)

    return wrapper


def current_assistant() -> dict[str, Any]:
    return g.current_assistant
