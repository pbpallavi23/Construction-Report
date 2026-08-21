from __future__ import annotations

from flask import Blueprint

from app.api.v1.routers import (
    ai,
    assistants,
    auth,
    ocr,
    pictures,
    reports,
    sites,
    speech,
)


blueprints: list[Blueprint] = [
    auth.bp,
    sites.bp,
    assistants.bp,
    reports.bp,
    ocr.bp,
    speech.bp,
    pictures.bp,
    ai.bp,
]
