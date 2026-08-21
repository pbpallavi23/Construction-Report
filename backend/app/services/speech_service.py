from __future__ import annotations

import math
import os
import time
from functools import lru_cache
from typing import Any, BinaryIO

from app.core.config import settings
from app.core.exceptions import NotFoundError, ValidationAppError
from app.core.storage import absolute_path
from app.core.utils import new_id, utc_now_iso
from app.persistence import repositories


@lru_cache(maxsize=1)
def _model():
    """Lazily loads the local Whisper model once per process and reuses it.

    Loading is deferred (rather than at import time) so the rest of the API
    stays fast to start up and unaffected if speech-to-text is never used.
    The model weights are cached on disk after the first download, so no
    network access is needed on subsequent runs.
    """
    from faster_whisper import WhisperModel

    os.makedirs(settings.STT_MODEL_CACHE_DIR, exist_ok=True)
    return WhisperModel(
        settings.STT_MODEL_SIZE,
        device=settings.STT_DEVICE,
        compute_type=settings.STT_COMPUTE_TYPE,
        download_root=settings.STT_MODEL_CACHE_DIR,
    )


def transcribe(
    audio: BinaryIO | str | None,
    duration_seconds: int | None = None,
) -> dict[str, Any]:
    """Transcribes recorded speech to text using a local Whisper model.

    `audio` is either a file-like object (e.g. the multipart upload stream)
    or a path to an audio file on disk. Runs fully offline once the model
    has been downloaded once.
    """
    if audio is None:
        raise ValidationAppError("No audio file was provided.")

    started = time.monotonic()
    segment_iter, info = _model().transcribe(
        audio,
        language=settings.STT_LANGUAGE,
        vad_filter=True,
    )


    segments = list(segment_iter)
    processing_ms = int((time.monotonic() - started) * 1000)

    text = " ".join(segment.text.strip() for segment in segments).strip()
    if not text:
        raise ValidationAppError(
            "Could not detect any speech in the recording. Try again closer "
            "to the microphone or in a quieter environment."
        )





    weighted_conf = 0.0
    total_duration = 0.0
    for segment in segments:
        segment_duration = max(segment.end - segment.start, 0.01)
        weighted_conf += math.exp(segment.avg_logprob) * segment_duration
        total_duration += segment_duration


    confidence = round(weighted_conf / total_duration, 2) if total_duration else 0.0

    return {
        "transcript": text,
        "confidence": confidence,
        "duration_seconds": duration_seconds
        if duration_seconds is not None
        else round(info.duration),
        "processing_ms": processing_ms,
    }


def save_note(
    site_id: str,
    transcript: str = "",
    file_path: str | None = None,
    user_id: str | None = None,
) -> dict[str, Any]:
    if repositories.sites.get(site_id) is None:
        raise ValidationAppError(f"Site '{site_id}' does not exist.")
    record = {
        "id": new_id("note"),
        "site_id": site_id,
        "user_id": user_id,
        "transcript": transcript,
        "file_path": file_path,
        "created_at": utc_now_iso(),
    }
    return repositories.voice_notes.add(record)


def list_notes(site_id: str | None = None) -> list[dict[str, Any]]:
    notes = repositories.voice_notes.list(site_id)
    return sorted(notes, key=lambda n: n["created_at"], reverse=True)


def delete_note(note_id: str) -> None:
    record = repositories.voice_notes.get(note_id)
    if record is None:
        raise NotFoundError(f"Voice note '{note_id}' was not found.")
    repositories.voice_notes.delete(note_id)
    file_path = record.get("file_path")
    if file_path:
        try:
            os.remove(absolute_path(file_path))
        except FileNotFoundError:
            pass
