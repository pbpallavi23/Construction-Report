from __future__ import annotations

import os
import uuid

from werkzeug.datastructures import FileStorage
from werkzeug.utils import secure_filename

from app.core.config import settings

VOICE_SUBDIR = "voice"
PICTURE_SUBDIR = "pictures"
REPORT_PDF_SUBDIR = "reports"
OCR_SCAN_SUBDIR = "ocr_scans"


def _extension(filename: str | None) -> str:
    if not filename:
        return ""
    return os.path.splitext(secure_filename(filename))[1].lower()


def save_upload(file: FileStorage, subdir: str) -> str:
    name = f"{uuid.uuid4().hex}{_extension(file.filename)}"
    target_dir = os.path.join(settings.UPLOAD_DIR, subdir)
    os.makedirs(target_dir, exist_ok=True)
    file.save(os.path.join(target_dir, name))
    return f"{subdir}/{name}"


def save_bytes(data: bytes, subdir: str, filename: str) -> str:
    target_dir = os.path.join(settings.UPLOAD_DIR, subdir)
    os.makedirs(target_dir, exist_ok=True)
    with open(os.path.join(target_dir, filename), "wb") as f:
        f.write(data)
    return f"{subdir}/{filename}"


def delete_file(relative_path: str) -> None:
    try:
        os.remove(absolute_path(relative_path))
    except FileNotFoundError:
        pass


def absolute_path(relative_path: str) -> str:
    return os.path.join(settings.UPLOAD_DIR, relative_path)