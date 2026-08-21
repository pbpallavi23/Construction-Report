from __future__ import annotations

from flask import Blueprint

from app.api.deps import current_assistant, require_auth
from app.api.responses import body, json_ok, require_fields
from app.services import auth_service

bp = Blueprint("auth", __name__)


@bp.post("/auth/login")
def login():
    payload = body()
    require_fields(payload, "email", "password")
    assistant = auth_service.authenticate(payload["email"], payload["password"])
    return json_ok(auth_service.issue_token(assistant))


@bp.get("/auth/me")
@require_auth
def me():
    return json_ok(current_assistant())


@bp.post("/auth/logout")
@require_auth
def logout():
    return json_ok({"message": "Logged out successfully."})
