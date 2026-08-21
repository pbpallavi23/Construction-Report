from __future__ import annotations

from typing import Any

from app.core.exceptions import NotFoundError, ValidationAppError
from app.core.utils import new_id
from app.persistence import repositories

_EDITABLE_FIELDS = ("site_name", "address", "phase", "latitude", "longitude")


def create_site(
    site_name: str,
    address: str,
    assigned_assistant_id: str | None = None,
    site_code: str | None = None,
    status: str = "active",
    phase: str | None = None,
    latitude: float | None = None,
    longitude: float | None = None,
) -> dict[str, Any]:
    site_name = (site_name or "").strip()
    address = (address or "").strip()
    if not site_name or not address:
        raise ValidationAppError("Site name and address are required.")
    assigned = (assigned_assistant_id or "").strip() or None
    if assigned is not None and repositories.assistants.get(assigned) is None:
        raise ValidationAppError(f"Assigned user '{assigned}' does not exist.")
    record = {
        "site_id": new_id("site"),
        "site_name": site_name,
        "site_code": (site_code or "").strip() or None,
        "address": address,
        "status": (status or "active").strip(),
        "assigned_assistant_id": assigned,
        "phase": (phase or "").strip() or None,
        "latitude": latitude,
        "longitude": longitude,
    }
    return repositories.sites.add(record)


def delete_site(site_id: str) -> None:
    if not repositories.sites.delete(site_id):
        raise NotFoundError(f"Site '{site_id}' was not found.")


def _with_assistant(site: dict[str, Any]) -> dict[str, Any]:
    assistant_id = site.get("assigned_assistant_id")
    site["assigned_assistant"] = (
        repositories.assistants.get(assistant_id) if assistant_id else None
    )
    return site


def list_sites(assigned_assistant_id: str | None = None) -> list[dict[str, Any]]:
    return repositories.sites.list(assigned_assistant_id=assigned_assistant_id)


def get_site(site_id: str) -> dict[str, Any]:
    row = repositories.sites.get(site_id)
    if row is None:
        raise NotFoundError(f"Site '{site_id}' was not found.")
    return row


def get_site_detail(site_id: str) -> dict[str, Any]:
    return _with_assistant(get_site(site_id))


def update_site(site_id: str, changes: dict[str, Any]) -> dict[str, Any]:
    updates = {
        key: value
        for key, value in changes.items()
        if key in _EDITABLE_FIELDS and value is not None
    }
    row = repositories.sites.update(site_id, updates)
    if row is None:
        raise NotFoundError(f"Site '{site_id}' was not found.")
    return _with_assistant(row)


def get_active_site_for_assistant(assistant_id: str) -> dict[str, Any] | None:
    sites = repositories.sites.list()
    chosen = next(
        (
            site
            for site in sites
            if site.get("assigned_assistant_id") == assistant_id
            and site.get("status") == "active"
        ),
        None,
    )
    if chosen is None:
        chosen = next((site for site in sites if site.get("status") == "active"), None)
    if chosen is None:
        chosen = sites[0] if sites else None
    if chosen is None:
        return None
    return _with_assistant(chosen)
