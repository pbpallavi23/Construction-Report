from __future__ import annotations

import os
from typing import Any

from app.core.exceptions import NotFoundError, ValidationAppError
from app.core.storage import absolute_path
from app.core.utils import new_id, utc_now_iso
from app.persistence import repositories


def list_pictures(site_id: str | None = None) -> list[dict[str, Any]]:
    pictures = repositories.pictures.list(site_id)
    return sorted(pictures, key=lambda p: p.get("created_at") or "", reverse=True)


def save_picture(
    site_id: str,
    file_path: str,
    caption: str | None = None,
    user_id: str | None = None,
) -> dict[str, Any]:
    if not file_path:
        raise ValidationAppError("An image file is required.")
    if repositories.sites.get(site_id) is None:
        raise ValidationAppError(f"Site '{site_id}' does not exist.")
    record = {
        "id": new_id("pic"),
        "site_id": site_id,
        "user_id": user_id,
        "file_path": file_path,
        "caption": (caption or "").strip() or None,
        "created_at": utc_now_iso(),
    }
    return repositories.pictures.add(record)


def delete_picture(picture_id: str) -> None:
    record = repositories.pictures.get(picture_id)
    if record is None:
        raise NotFoundError(f"Picture '{picture_id}' was not found.")
    repositories.pictures.delete(picture_id)
    file_path = record.get("file_path")
    if file_path:
        try:
            os.remove(absolute_path(file_path))
        except FileNotFoundError:
            pass
