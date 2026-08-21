from __future__ import annotations

from dataclasses import dataclass

from app.persistence.base import (
    AssistantRepository,
    PictureRepository,
    ReportRepository,
    SiteRepository,
    VoiceNoteRepository,
)


@dataclass(frozen=True)
class RepositoryRegistry:
    assistants: AssistantRepository
    sites: SiteRepository
    reports: ReportRepository
    voice_notes: VoiceNoteRepository
    pictures: PictureRepository
