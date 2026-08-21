from __future__ import annotations

import copy
from typing import Any

from app.persistence.base import (
    AssistantRepository,
    PictureRepository,
    ReportRepository,
    SiteRepository,
    VoiceNoteRepository,
)
from app.persistence.memory.store import InMemoryStore

Record = dict[str, Any]


def _clone(record: Record | None) -> Record | None:
    return copy.deepcopy(record) if record is not None else None


def _clone_all(records: Any) -> list[Record]:
    return [copy.deepcopy(record) for record in records]


class InMemoryAssistantRepository(AssistantRepository):
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    def list(self) -> list[Record]:
        return _clone_all(self._store.assistants.values())

    def get(self, assistant_id: str) -> Record | None:
        return _clone(self._store.assistants.get(assistant_id))

    def find_by_email(self, email: str) -> Record | None:
        target = email.strip().lower()
        for record in self._store.assistants.values():
            if record["email"].strip().lower() == target:
                return _clone(record)
        return None

    def update(self, assistant_id: str, changes: Record) -> Record | None:
        record = self._store.assistants.get(assistant_id)
        if record is None:
            return None
        record.update(changes)
        return _clone(record)

    def add(self, record: Record) -> Record:
        self._store.assistants[record["assistant_id"]] = copy.deepcopy(record)
        return _clone(self._store.assistants[record["assistant_id"]])

    def delete(self, assistant_id: str) -> bool:
        return self._store.assistants.pop(assistant_id, None) is not None


class InMemorySiteRepository(SiteRepository):
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    def list(self, assigned_assistant_id: str | None = None) -> list[Record]:
        records = self._store.sites.values()
        if assigned_assistant_id is not None:
            records = [
                record
                for record in records
                if record.get("assigned_assistant_id") == assigned_assistant_id
            ]
        return _clone_all(records)

    def get(self, site_id: str) -> Record | None:
        return _clone(self._store.sites.get(site_id))

    def update(self, site_id: str, changes: Record) -> Record | None:
        record = self._store.sites.get(site_id)
        if record is None:
            return None
        record.update(changes)
        return _clone(record)

    def add(self, record: Record) -> Record:
        self._store.sites[record["site_id"]] = copy.deepcopy(record)
        return _clone(self._store.sites[record["site_id"]])

    def delete(self, site_id: str) -> bool:
        return self._store.sites.pop(site_id, None) is not None


class InMemoryReportRepository(ReportRepository):
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    def list(self, site_id: str | None = None) -> list[Record]:
        records = self._store.reports.values()
        if site_id:
            records = [record for record in records if record["site_id"] == site_id]
        return _clone_all(records)

    def get(self, report_id: str) -> Record | None:
        return _clone(self._store.reports.get(report_id))

    def add(self, record: Record) -> Record:
        self._store.reports[record["id"]] = copy.deepcopy(record)
        return _clone(self._store.reports[record["id"]])

    def update(self, report_id: str, changes: Record) -> Record | None:
        record = self._store.reports.get(report_id)
        if record is None:
            return None
        record.update(changes)
        return _clone(record)

    def delete(self, report_id: str) -> bool:
        return self._store.reports.pop(report_id, None) is not None


class InMemoryVoiceNoteRepository(VoiceNoteRepository):
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    def list(self, site_id: str | None = None) -> list[Record]:
        records = self._store.voice_notes.values()
        if site_id:
            records = [record for record in records if record.get("site_id") == site_id]
        return _clone_all(records)

    def get(self, note_id: str) -> Record | None:
        return _clone(self._store.voice_notes.get(note_id))

    def add(self, record: Record) -> Record:
        self._store.voice_notes[record["id"]] = copy.deepcopy(record)
        return _clone(self._store.voice_notes[record["id"]])

    def delete(self, note_id: str) -> bool:
        return self._store.voice_notes.pop(note_id, None) is not None


class InMemoryPictureRepository(PictureRepository):
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    def list(self, site_id: str | None = None) -> list[Record]:
        records = self._store.pictures.values()
        if site_id:
            records = [record for record in records if record.get("site_id") == site_id]
        return _clone_all(records)

    def get(self, picture_id: str) -> Record | None:
        return _clone(self._store.pictures.get(picture_id))

    def add(self, record: Record) -> Record:
        self._store.pictures[record["id"]] = copy.deepcopy(record)
        return _clone(self._store.pictures[record["id"]])

    def delete(self, picture_id: str) -> bool:
        return self._store.pictures.pop(picture_id, None) is not None
