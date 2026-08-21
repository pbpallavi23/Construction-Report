from __future__ import annotations

import json
import sqlite3
import time
from contextlib import contextmanager
from typing import Any, Iterator

from app.core.config import settings
from app.core.logging import get_logger

logger = get_logger(__name__)

Record = dict[str, Any]













_CREATE_STATEMENTS: dict[str, str] = {
    "users": """
        CREATE TABLE IF NOT EXISTS users (
            userid     TEXT PRIMARY KEY,
            name       TEXT NOT NULL,
            password   TEXT NOT NULL,
            email      TEXT UNIQUE NOT NULL,
            role       TEXT,
            phone      TEXT,
            avatar_url TEXT
        )
    """,
    "site": """
        CREATE TABLE IF NOT EXISTS site (
            siteid     TEXT PRIMARY KEY,
            userid     TEXT,
            address    TEXT,
            site_name  TEXT,
            site_code  TEXT,
            status     TEXT,
            phase      TEXT,
            latitude   REAL,
            longitude  REAL,
            FOREIGN KEY (userid) REFERENCES users (userid) ON DELETE SET NULL
        )
    """,
    "reports": """
        CREATE TABLE IF NOT EXISTS reports (
            id      TEXT PRIMARY KEY,
            site_id TEXT NOT NULL,
            data    TEXT NOT NULL
        )
    """,
    "voice_notes": """
        CREATE TABLE IF NOT EXISTS voice_notes (
            voiceid    TEXT PRIMARY KEY,
            siteid     TEXT,
            userid     TEXT,
            transcript TEXT,
            file_path  TEXT,
            created_at TEXT,
            FOREIGN KEY (siteid) REFERENCES site (siteid) ON DELETE CASCADE,
            FOREIGN KEY (userid) REFERENCES users (userid) ON DELETE SET NULL
        )
    """,
    "pictures": """
        CREATE TABLE IF NOT EXISTS pictures (
            pictureid  TEXT PRIMARY KEY,
            siteid     TEXT,
            userid     TEXT,
            file_path  TEXT NOT NULL,
            caption    TEXT,
            created_at TEXT,
            FOREIGN KEY (siteid) REFERENCES site (siteid) ON DELETE CASCADE,
            FOREIGN KEY (userid) REFERENCES users (userid) ON DELETE SET NULL
        )
    """,
}



_COLUMNS: dict[str, tuple[str, ...]] = {
    "users": ("userid", "name", "password", "email", "role", "phone", "avatar_url"),
    "site": (
        "siteid", "userid", "address", "site_name", "site_code",
        "status", "phase", "latitude", "longitude",
    ),
    "reports": ("id", "site_id", "data"),
    "voice_notes": (
        "voiceid", "siteid", "userid", "transcript", "file_path", "created_at",
    ),
    "pictures": (
        "pictureid", "siteid", "userid", "file_path", "caption", "created_at",
    ),
}


@contextmanager
def connect() -> Iterator[sqlite3.Connection]:
    conn = sqlite3.connect(settings.DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    conn.execute("PRAGMA foreign_keys = ON")
    try:
        yield conn
        conn.commit()
    finally:
        conn.close()


def _table_exists(conn: sqlite3.Connection, table: str) -> bool:
    row = conn.execute(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()
    return row is not None


def _actual_columns(conn: sqlite3.Connection, table: str) -> set[str]:
    return {row["name"] for row in conn.execute(f"PRAGMA table_info({table})")}


def _table_sql(conn: sqlite3.Connection, table: str) -> str | None:
    row = conn.execute(
        "SELECT sql FROM sqlite_master WHERE type='table' AND name=?", (table,)
    ).fetchone()
    return row["sql"] if row else None


def _quarantine_mismatched_tables(conn: sqlite3.Connection) -> None:
    """If a table already exists but its columns don't match the current
    schema (e.g. it predates a later column rename), rename it aside
    instead of silently failing on every query. The renamed copy is kept
    (not dropped) so old data can still be inspected/migrated by hand.
    `CREATE TABLE IF NOT EXISTS` never fixes an existing mismatched table,
    so this runs before that statement on every startup.

    Must run with `PRAGMA foreign_keys = OFF` — SQLite auto-rewrites the
    FOREIGN KEY clause of every *other* table that references a table
    being renamed when foreign_keys is ON, which would silently repoint
    e.g. pictures/voice_notes at the renamed-away legacy table instead of
    the fresh one created right after. `_repair_stale_fk_targets` cleans up
    any table that got corrupted this way by an earlier run."""
    for table, expected in _COLUMNS.items():
        if not _table_exists(conn, table):
            continue
        actual = _actual_columns(conn, table)
        if actual == set(expected):
            continue
        backup_name = f"{table}_legacy_{int(time.time())}"
        logger.warning(
            "Schema mismatch on '%s' (expected %s, found %s) — renaming to '%s'.",
            table, sorted(expected), sorted(actual), backup_name,
        )
        conn.execute(f"ALTER TABLE {table} RENAME TO {backup_name}")


def _create_missing_tables(conn: sqlite3.Connection) -> None:
    for statement in _CREATE_STATEMENTS.values():
        conn.execute(statement)


def _repair_stale_fk_targets(conn: sqlite3.Connection) -> None:
    """Detect any table whose stored CREATE TABLE SQL points a foreign key
    at a "*_legacy_*" table (the corruption described above, whether from
    this run or an earlier one) and rebuild it fresh, copying its data
    across so its foreign keys point at the live tables again."""
    for table in _CREATE_STATEMENTS:
        if not _table_exists(conn, table):
            continue
        sql = _table_sql(conn, table) or ""
        if "_legacy_" not in sql:
            continue
        backup_name = f"{table}_fkfix_{int(time.time())}"
        logger.warning(
            "'%s' has a foreign key pointing at a renamed legacy table — "
            "rebuilding it and copying its data across (backup kept as '%s').",
            table, backup_name,
        )
        conn.execute(f"ALTER TABLE {table} RENAME TO {backup_name}")
        conn.execute(_CREATE_STATEMENTS[table])
        columns = ", ".join(_COLUMNS[table])
        try:
            conn.execute(
                f"INSERT INTO {table} ({columns}) "
                f"SELECT {columns} FROM {backup_name}"
            )
        except sqlite3.OperationalError as exc:
            logger.error(
                "Could not copy data back into '%s' from '%s': %s. "
                "The old data is still in '%s' for manual recovery.",
                table, backup_name, exc, backup_name,
            )


def init_db() -> None:
    conn = sqlite3.connect(settings.DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    try:


        conn.execute("PRAGMA foreign_keys = OFF")
        _quarantine_mismatched_tables(conn)
        _create_missing_tables(conn)
        _repair_stale_fk_targets(conn)
        conn.commit()
    finally:
        conn.execute("PRAGMA foreign_keys = ON")
        conn.close()
    logger.info("SQLite database ready at %s (no seed data)", settings.DATABASE_PATH)


def dumps(value: Any) -> str:
    return json.dumps(value)


def loads(text: str | None) -> Any:
    return json.loads(text) if text else None