from __future__ import annotations

from app.persistence.memory.repositories import (
    InMemoryAssistantRepository,
    InMemoryPictureRepository,
    InMemoryReportRepository,
    InMemorySiteRepository,
    InMemoryVoiceNoteRepository,
)
from app.persistence.memory.store import InMemoryStore
from app.persistence.registry import RepositoryRegistry


def build_memory_registry() -> RepositoryRegistry:
    store = InMemoryStore()
    return RepositoryRegistry(
        assistants=InMemoryAssistantRepository(store),
        sites=InMemorySiteRepository(store),
        reports=InMemoryReportRepository(store),
        voice_notes=InMemoryVoiceNoteRepository(store),
        pictures=InMemoryPictureRepository(store),
    )
