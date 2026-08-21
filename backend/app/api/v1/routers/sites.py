from __future__ import annotations

from flask import Blueprint, request

from app.api.deps import current_assistant, require_auth
from app.api.responses import body, json_ok
from app.core.exceptions import NotFoundError
from app.services import site_service

bp = Blueprint("sites", __name__)


@bp.get("/sites")
@require_auth
def list_sites():
    mine = request.args.get("mine", "false").strip().lower() in {"1", "true", "yes"}
    assigned = current_assistant()["assistant_id"] if mine else None
    return json_ok(site_service.list_sites(assigned_assistant_id=assigned))


@bp.get("/sites/active")
@require_auth
def active_site():
    site = site_service.get_active_site_for_assistant(
        current_assistant()["assistant_id"]
    )
    if site is None:
        raise NotFoundError("No site is available yet. Create one in the admin dashboard.")
    detail = site_service.get_site_detail(site["site_id"])
    return json_ok(detail)


@bp.get("/sites/<site_id>")
@require_auth
def get_site(site_id: str):
    return json_ok(site_service.get_site_detail(site_id))


@bp.patch("/sites/<site_id>")
@require_auth
def update_site(site_id: str):
    updated = site_service.update_site(site_id, body())
    return json_ok(updated)
