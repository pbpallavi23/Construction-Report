from __future__ import annotations

from abc import ABC, abstractmethod
from typing import Any

Record = dict[str, Any]


class AssistantRepository(ABC):
    @abstractmethod
    def list(self) -> list[Record]:
        ...

    @abstractmethod
    def get(self, assistant_id: str) -> Record | None:
        ...

    @abstractmethod
    def find_by_email(self, email: str) -> Record | None:
        ...

    @abstractmethod
    def update(self, assistant_id: str, changes: Record) -> Record | None:
        ...

    @abstractmethod
    def add(self, record: Record) -> Record:
        ...

    @abstractmethod
    def delete(self, assistant_id: str) -> bool:
        ...


class SiteRepository(ABC):
    @abstractmethod
    def list(self, assigned_assistant_id: str | None = None) -> list[Record]:
        ...

    @abstractmethod
    def get(self, site_id: str) -> Record | None:
        ...

    @abstractmethod
    def update(self, site_id: str, changes: Record) -> Record | None:
        ...

    @abstractmethod
    def add(self, record: Record) -> Record:
        ...

    @abstractmethod
    def delete(self, site_id: str) -> bool:
        ...


class ReportRepository(ABC):
    @abstractmethod
    def list(self, site_id: str | None = None) -> list[Record]:
        ...

    @abstractmethod
    def get(self, report_id: str) -> Record | None:
        ...

    @abstractmethod
    def add(self, record: Record) -> Record:
        ...

    @abstractmethod
    def update(self, report_id: str, changes: Record) -> Record | None:
        ...

    @abstractmethod
    def delete(self, report_id: str) -> bool:
        ...


class VoiceNoteRepository(ABC):
    @abstractmethod
    def list(self, site_id: str | None = None) -> list[Record]:
        ...

    @abstractmethod
    def get(self, note_id: str) -> Record | None:
        ...

    @abstractmethod
    def add(self, record: Record) -> Record:
        ...

    @abstractmethod
    def delete(self, note_id: str) -> bool:
        ...


class PictureRepository(ABC):
    @abstractmethod
    def list(self, site_id: str | None = None) -> list[Record]:
        ...

    @abstractmethod
    def get(self, picture_id: str) -> Record | None:
        ...

    @abstractmethod
    def add(self, record: Record) -> Record:
        ...

    @abstractmethod
    def delete(self, picture_id: str) -> bool:
        ...
