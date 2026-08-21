from __future__ import annotations

from flask import Blueprint

from app.api.deps import require_auth
from app.api.responses import body, json_ok
from app.services import ai_service

bp = Blueprint("ai", __name__)


@bp.post("/ai/suggestions")
@require_auth
def suggestions():
    data = body()
    context = data.get("context", "daily_report")
    prompt = data.get("prompt")
    site_id = data.get("site_id")
    return json_ok(ai_service.suggest(context, prompt, site_id))