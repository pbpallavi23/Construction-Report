from __future__ import annotations

from flask import Blueprint, request

from app.api.deps import current_assistant, require_auth
from app.api.responses import body, json_ok, require_fields
from app.core.storage import VOICE_SUBDIR, save_upload
from app.services import speech_service

bp = Blueprint("speech", __name__)


@bp.post("/speech/transcribe")
@require_auth
def transcribe():
    upload = request.files.get("file")
    if upload is None:
        require_fields({}, "file")
    try:
        duration_seconds = int(request.form.get("duration_seconds"))
    except (TypeError, ValueError):
        duration_seconds = None
    return json_ok(speech_service.transcribe(upload.stream, duration_seconds))


@bp.post("/speech/notes")
@require_auth
def save_note():
    """Save a voice note. Accepts either:
    - JSON  {site_id, transcript}                         (transcript only)
    - multipart form  file=<audio> site_id=.. transcript=..  (stores the file)
    """
    user_id = current_assistant().get("assistant_id")
    upload = request.files.get("file")
    if upload is not None:
        site_id = request.form.get("site_id", "")
        transcript = request.form.get("transcript", "")
        require_fields({"site_id": site_id}, "site_id")
        file_path = save_upload(upload, VOICE_SUBDIR)
        note = speech_service.save_note(site_id, transcript, file_path, user_id)
    else:
        data = body()
        require_fields(data, "site_id", "transcript")
        note = speech_service.save_note(
            data["site_id"], data["transcript"], None, user_id
        )
    return json_ok(note)


@bp.get("/speech/notes")
@require_auth
def list_notes():
    site_id = request.args.get("site_id")
    return json_ok(speech_service.list_notes(site_id))


@bp.delete("/speech/notes/<note_id>")
@require_auth
def delete_note(note_id: str):
    speech_service.delete_note(note_id)
    return json_ok({"id": note_id, "deleted": True})
