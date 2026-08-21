from __future__ import annotations

from flask import Blueprint, request

from app.api.deps import current_assistant, require_auth
from app.api.responses import json_ok, require_fields
from app.core.storage import PICTURE_SUBDIR, save_upload
from app.services import picture_service

bp = Blueprint("pictures", __name__)


@bp.post("/pictures")
@require_auth
def upload_picture():
    """Upload a picture (multipart: file=<image> site_id=.. caption=..).
    Stores the image on disk and records its path in the pictures table."""
    upload = request.files.get("file")
    if upload is None:
        require_fields({}, "file")
    site_id = request.form.get("site_id", "")
    require_fields({"site_id": site_id}, "site_id")
    file_path = save_upload(upload, PICTURE_SUBDIR)
    record = picture_service.save_picture(
        site_id=site_id,
        file_path=file_path,
        caption=request.form.get("caption"),
        user_id=current_assistant().get("assistant_id"),
    )
    return json_ok(record)


@bp.get("/pictures")
@require_auth
def list_pictures():
    site_id = request.args.get("site_id")
    return json_ok(picture_service.list_pictures(site_id))


@bp.delete("/pictures/<picture_id>")
@require_auth
def delete_picture(picture_id: str):
    picture_service.delete_picture(picture_id)
    return json_ok({"id": picture_id, "deleted": True})
