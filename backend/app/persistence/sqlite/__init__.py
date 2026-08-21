from __future__ import annotations

from app.persistence.registry import RepositoryRegistry
from app.persistence.sqlite.database import init_db
from app.persistence.sqlite.repositories import (
    SqliteAssistantRepository,
    SqlitePictureRepository,
    SqliteReportRepository,
    SqliteSiteRepository,
    SqliteVoiceNoteRepository,
)


def build_sqlite_registry() -> RepositoryRegistry:
    init_db()
    return RepositoryRegistry(
        assistants=SqliteAssistantRepository(),
        sites=SqliteSiteRepository(),
        reports=SqliteReportRepository(),
        voice_notes=SqliteVoiceNoteRepository(),
        pictures=SqlitePictureRepository(),
    )


__all__ = ["build_sqlite_registry"]
