from __future__ import annotations

from flask import Blueprint, request

from app.api.deps import current_assistant, require_auth
from app.api.responses import json_ok
from app.core.storage import OCR_SCAN_SUBDIR, PICTURE_SUBDIR, delete_file, save_upload
from app.services import ocr_service, picture_service

bp = Blueprint("ocr", __name__)


@bp.post("/ocr/scan")
@require_auth
def scan():
    upload = request.files.get("file")
    site_id = request.form.get("site_id")

    if upload is None:
        return json_ok(ocr_service.extract_text(None))

    if site_id:
        file_path = save_upload(upload, PICTURE_SUBDIR)
        picture_service.save_picture(
            site_id=site_id,
            file_path=file_path,
            caption="OCR scan",
            user_id=current_assistant().get("assistant_id"),
        )
        return json_ok(ocr_service.extract_text(file_path))

    file_path = save_upload(upload, OCR_SCAN_SUBDIR)
    try:
        return json_ok(ocr_service.extract_text(file_path))
    finally:
        delete_file(file_path)