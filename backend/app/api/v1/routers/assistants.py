from __future__ import annotations

from flask import Blueprint

from app.api.deps import current_assistant, require_auth
from app.api.responses import body, json_ok
from app.services import assistant_service

bp = Blueprint("assistants", __name__)


@bp.get("/assistants")
@require_auth
def list_assistants():
    return json_ok(assistant_service.list_assistants())


@bp.get("/assistants/<assistant_id>")
@require_auth
def get_assistant(assistant_id: str):
    return json_ok(assistant_service.get_assistant(assistant_id))


@bp.get("/profile")
@require_auth
def get_profile():
    return json_ok(current_assistant())


@bp.patch("/profile")
@require_auth
def update_profile():
    updated = assistant_service.update_profile(
        current_assistant()["assistant_id"], body()
    )
    return json_ok(updated)
