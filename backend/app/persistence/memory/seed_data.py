from __future__ import annotations

from typing import Any

Record = dict[str, Any]


def build_seed() -> dict[str, dict[str, Record]]:
    """No preloaded data. All records are created dynamically at runtime
    (via the admin dashboard or the API). Returns empty tables."""
    return {
        "assistants": {},
        "sites": {},
        "reports": {},
    }
