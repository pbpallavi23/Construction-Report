from __future__ import annotations

from typing import Any

from app.persistence.memory.seed_data import build_seed

Record = dict[str, Any]


class InMemoryStore:
    def __init__(self) -> None:
        seed = build_seed()
        self.assistants: dict[str, Record] = seed["assistants"]
        self.sites: dict[str, Record] = seed["sites"]
        self.reports: dict[str, Record] = seed["reports"]
        self.voice_notes: dict[str, Record] = {}
        self.pictures: dict[str, Record] = {}
