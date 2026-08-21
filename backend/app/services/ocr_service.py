from __future__ import annotations

import base64
import json
import time
from typing import Any

import requests

from app.core.config import settings
from app.core.logging import get_logger
from app.core.storage import absolute_path

logger = get_logger(__name__)

_PROMPT = (
    "You are reading a photo of a document from a UK construction site "
    "(e.g. a delivery note, invoice, permit, or similar paperwork). Return "
    "ONLY a JSON object with these keys: "
    '"document_type" (a short label for what kind of document this is, or '
    '"Unknown" if unclear), "raw_text" (your best transcription of all '
    "visible text, preserving line breaks as \\n), and \"fields\" (a JSON "
    'array of {"label": ..., "value": ...} objects for the most useful '
    "structured details you can read - e.g. date, site, supplier, item "
    "list - only include a field if you can actually read its value). "
    "Never invent text that isn't visible in the image."
)


def extract_text(file_path: str | None) -> dict[str, Any]:
    start = time.monotonic()

    if not file_path:
        return _empty_result(start)

    try:
        with open(absolute_path(file_path), "rb") as f:
            image_b64 = base64.b64encode(f.read()).decode("ascii")
    except OSError as exc:
        logger.warning("Could not read scan '%s' for OCR: %s", file_path, exc)
        return _empty_result(start)

    try:
        resp = requests.post(
            f"{settings.OLLAMA_BASE_URL}/api/generate",
            json={
                "model": settings.OLLAMA_VISION_MODEL,
                "prompt": _PROMPT,
                "images": [image_b64],
                "format": "json",
                "stream": False,
            },
            timeout=settings.OLLAMA_TIMEOUT_SECONDS,
        )
        resp.raise_for_status()
        parsed = json.loads(resp.json().get("response", ""))
    except (requests.RequestException, json.JSONDecodeError) as exc:
        logger.warning("Ollama OCR call failed for '%s': %s", file_path, exc)
        return _empty_result(start)

    fields = parsed.get("fields") if isinstance(parsed, dict) else None
    if not isinstance(fields, list):
        fields = []
    clean_fields = [
        {"label": str(f.get("label", "")), "value": str(f.get("value", ""))}
        for f in fields
        if isinstance(f, dict) and f.get("label") and f.get("value")
    ]

    return {
        "document_type": (parsed.get("document_type") or "Unknown")
        if isinstance(parsed, dict)
        else "Unknown",
        "raw_text": (parsed.get("raw_text") or "") if isinstance(parsed, dict) else "",
        "fields": clean_fields,
        "confidence": 0.75 if clean_fields else 0.4,
        "processing_ms": int((time.monotonic() - start) * 1000),
    }


def _empty_result(start: float) -> dict[str, Any]:
    return {
        "document_type": "Unknown",
        "raw_text": "",
        "fields": [],
        "confidence": 0.0,
        "processing_ms": int((time.monotonic() - start) * 1000),
    }