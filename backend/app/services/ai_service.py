from __future__ import annotations

import base64
import json
import time
from typing import Any

import requests

from app.core.config import settings
from app.core.logging import get_logger
from app.core.storage import absolute_path
from app.persistence import repositories

logger = get_logger(__name__)

_SUGGEST_CONTEXT_LABELS: dict[str, str] = {
    "daily_report": "a daily site progress report",
    "safety": "a site safety observation",
    "observation": "a general site observation",
}


def suggest(
    context: str,
    prompt: str | None = None,
    site_id: str | None = None,
) -> dict[str, Any]:
    start = time.monotonic()
    context_label = _SUGGEST_CONTEXT_LABELS.get(context, _SUGGEST_CONTEXT_LABELS["daily_report"])

    site_notes = _recent_site_context(site_id) if site_id else ""

    instruction = (
        f"You are drafting {context_label} for a UK construction site. "
        "Return ONLY a JSON object with a \"suggestions\" key: a JSON array "
        "of 1-3 objects, each with \"title\" (a short heading), \"text\" (a "
        "factual 1-3 sentence draft, plain English), and \"confidence\" (a "
        "number 0-1 for how well-supported the text is by the material "
        "given). Never invent specific facts, numbers, or names that "
        "aren't in the material below.\n\n"
    )
    if site_notes:
        instruction += f"RECENT SITE MATERIAL:\n{site_notes}\n\n"
    else:
        instruction += (
            "No recent site material was provided - keep suggestions "
            "generic and low-confidence, as placeholders for the user to "
            "edit.\n\n"
        )
    if prompt:
        instruction += f"USER NOTE TO INCORPORATE:\n{prompt.strip()}\n"

    suggestions = _generate_suggestions(instruction)

    return {
        "suggestions": suggestions,
        "processing_ms": int((time.monotonic() - start) * 1000),
    }


def _recent_site_context(site_id: str) -> str:
    notes = repositories.voice_notes.list(site_id)
    recent_notes = sorted(
        notes, key=lambda n: n.get("created_at") or "", reverse=True
    )[:5]
    parts = [
        f"[Voice note, {n.get('created_at', '')}]: {(n.get('transcript') or '').strip()}"
        for n in recent_notes
        if (n.get("transcript") or "").strip()
    ]
    return "\n".join(parts)


def _generate_suggestions(instruction: str) -> list[dict[str, Any]]:
    if not ollama_available():
        return []
    try:
        resp = requests.post(
            f"{settings.OLLAMA_BASE_URL}/api/generate",
            json={
                "model": settings.OLLAMA_TEXT_MODEL,
                "prompt": instruction,
                "format": "json",
                "stream": False,
            },
            timeout=settings.OLLAMA_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        parsed = json.loads(resp.json().get("response", ""))
    except (requests.RequestException, json.JSONDecodeError) as exc:
        logger.warning("Ollama suggestion call failed: %s", exc)
        return []

    raw_suggestions = parsed.get("suggestions") if isinstance(parsed, dict) else None
    if not isinstance(raw_suggestions, list):
        return []

    cleaned: list[dict[str, Any]] = []
    for s in raw_suggestions:
        if not isinstance(s, dict) or not s.get("title") or not s.get("text"):
            continue
        try:
            confidence = float(s.get("confidence", 0.5))
        except (TypeError, ValueError):
            confidence = 0.5
        cleaned.append({
            "title": str(s["title"]),
            "text": str(s["text"]),
            "confidence": max(0.0, min(1.0, confidence)),
        })
    return cleaned

def ollama_available() -> bool:
    if not settings.AI_AUTOFILL_ENABLED:
        return False
    try:
        resp = requests.get(f"{settings.OLLAMA_BASE_URL}/api/tags", timeout=3)
        return resp.ok
    except requests.RequestException:
        return False


def _describe_image(file_path: str) -> str | None:
    try:
        with open(absolute_path(file_path), "rb") as f:
            image_b64 = base64.b64encode(f.read()).decode("ascii")
    except OSError as exc:
        logger.warning("Could not read picture '%s' for AI analysis: %s", file_path, exc)
        return None

    prompt = (
        "You are looking at a photo from a construction site that may be "
        "attached to a health & safety incident report. In 2-3 factual "
        "sentences, describe: any visible injury, hazard, damage, or unsafe "
        "condition; where on the site this appears to be; and the "
        "approximate body part affected if a person's injury is visible. "
        "If nothing incident-related is visible, say so plainly. Do not "
        "guess at information that isn't visible in the image."
    )
    try:
        resp = requests.post(
            f"{settings.OLLAMA_BASE_URL}/api/generate",
            json={
                "model": settings.OLLAMA_VISION_MODEL,
                "prompt": prompt,
                "images": [image_b64],
                "stream": False,
            },
            timeout=settings.OLLAMA_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        return resp.json().get("response", "").strip() or None
    except requests.RequestException as exc:
        logger.warning("Ollama vision call failed for '%s': %s", file_path, exc)
        return None


def _extract_fields_json(
    context_text: str,
    field_keys: list[str],
    guidance: str,
) -> dict[str, Any] | None:
    prompt = (
        "You are filling in a UK construction site incident report from "
        "site notes and photo descriptions below. Return ONLY a JSON object "
        "with exactly these keys: " + ", ".join(field_keys) + ". "
        "For any field you cannot determine from the material given, use "
        "JSON null - never invent details, names, dates, or numbers that "
        "are not clearly stated or shown. Dates must be DD/MM/YYYY and "
        "times 24-hour HH:MM if present.\n\n" + guidance + "\n\n"
        "SITE MATERIAL:\n" + context_text
    )
    try:
        resp = requests.post(
            f"{settings.OLLAMA_BASE_URL}/api/generate",
            json={
                "model": settings.OLLAMA_TEXT_MODEL,
                "prompt": prompt,
                "format": "json",
                "stream": False,
            },
            timeout=settings.OLLAMA_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        raw = resp.json().get("response", "")
        parsed = json.loads(raw)
        return parsed if isinstance(parsed, dict) else None
    except (requests.RequestException, json.JSONDecodeError) as exc:
        logger.warning("Ollama text extraction failed: %s", exc)
        return None


def autofill_incident_report(
    pictures: list[dict[str, Any]],
    notes: list[dict[str, Any]],
    field_keys: list[str],
    guidance: str,
) -> dict[str, Any]:
    blank = {key: None for key in field_keys}

    if not ollama_available():
        return {
            "fields": blank,
            "ai_available": False,
            "used_picture_ids": [],
            "used_note_ids": [],
        }

    recent_pictures = sorted(
        pictures, key=lambda p: p.get("created_at") or "", reverse=True
    )[: settings.AI_AUTOFILL_MAX_PICTURES]
    recent_notes = sorted(
        notes, key=lambda n: n.get("created_at") or "", reverse=True
    )[: settings.AI_AUTOFILL_MAX_NOTES]

    context_parts: list[str] = []
    used_picture_ids: list[str] = []
    for pic in recent_pictures:
        description = _describe_image(pic["file_path"])
        if description:
            context_parts.append(f"[Photo, {pic.get('created_at', '')}]: {description}")
            used_picture_ids.append(pic["id"])

    used_note_ids: list[str] = []
    for note in recent_notes:
        transcript = (note.get("transcript") or "").strip()
        if transcript:
            context_parts.append(
                f"[Voice note, {note.get('created_at', '')}]: {transcript}"
            )
            used_note_ids.append(note["id"])

    if not context_parts:
        return {
            "fields": blank,
            "ai_available": True,
            "used_picture_ids": [],
            "used_note_ids": [],
        }

    context_text = "\n".join(context_parts)
    fields = _extract_fields_json(context_text, field_keys, guidance)
    if fields is None:
        return {
            "fields": blank,
            "ai_available": True,
            "used_picture_ids": used_picture_ids,
            "used_note_ids": used_note_ids,
        }

    clean_fields = {key: fields.get(key) for key in field_keys}
    return {
        "fields": clean_fields,
        "ai_available": True,
        "used_picture_ids": used_picture_ids,
        "used_note_ids": used_note_ids,
    }