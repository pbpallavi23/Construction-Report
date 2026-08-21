from __future__ import annotations

from typing import Any

from app.persistence.base import (
    AssistantRepository,
    PictureRepository,
    ReportRepository,
    SiteRepository,
    VoiceNoteRepository,
)
from app.persistence.sqlite.database import connect, dumps, loads

Record = dict[str, Any]










_USER_MAP = {
    "assistant_id": "userid",
    "full_name": "name",
    "password_hash": "password",
    "email": "email",
    "role": "role",
    "phone": "phone",
    "avatar_url": "avatar_url",
}
_SITE_MAP = {
    "site_id": "siteid",
    "assigned_assistant_id": "userid",
    "address": "address",
    "site_name": "site_name",
    "site_code": "site_code",
    "status": "status",
    "phase": "phase",
    "latitude": "latitude",
    "longitude": "longitude",
}


def _user_to_dict(row) -> Record:
    return {app: row[col] for app, col in _USER_MAP.items()}


def _site_to_dict(row) -> Record:
    return {app: row[col] for app, col in _SITE_MAP.items()}


class SqliteAssistantRepository(AssistantRepository):
    def list(self) -> list[Record]:
        with connect() as c:
            return [_user_to_dict(r) for r in c.execute("SELECT * FROM users")]

    def get(self, assistant_id: str) -> Record | None:
        with connect() as c:
            row = c.execute(
                "SELECT * FROM users WHERE userid = ?", (assistant_id,)
            ).fetchone()
            return _user_to_dict(row) if row else None

    def find_by_email(self, email: str) -> Record | None:
        with connect() as c:
            row = c.execute(
                "SELECT * FROM users WHERE email = ?", (email.strip().lower(),)
            ).fetchone()
            return _user_to_dict(row) if row else None

    def update(self, assistant_id: str, changes: Record) -> Record | None:
        cols = {_USER_MAP[k]: v for k, v in changes.items() if k in _USER_MAP}
        if cols:
            assignments = ", ".join(f"{col} = ?" for col in cols)
            with connect() as c:
                cur = c.execute(
                    f"UPDATE users SET {assignments} WHERE userid = ?",
                    (*cols.values(), assistant_id),
                )
                if cur.rowcount == 0:
                    return None
        return self.get(assistant_id)

    def add(self, record: Record) -> Record:
        cols = {col: record.get(app) for app, col in _USER_MAP.items()}
        if cols.get("email"):
            cols["email"] = cols["email"].strip().lower()
        columns = ", ".join(cols)
        placeholders = ", ".join("?" for _ in cols)
        with connect() as c:
            c.execute(
                f"INSERT INTO users ({columns}) VALUES ({placeholders})",
                tuple(cols.values()),
            )
        return self.get(record["assistant_id"])

    def delete(self, assistant_id: str) -> bool:
        with connect() as c:
            cur = c.execute("DELETE FROM users WHERE userid = ?", (assistant_id,))
            return cur.rowcount > 0


class SqliteSiteRepository(SiteRepository):
    def list(self, assigned_assistant_id: str | None = None) -> list[Record]:
        with connect() as c:
            if assigned_assistant_id is None:
                rows = c.execute("SELECT * FROM site")
            else:
                rows = c.execute(
                    "SELECT * FROM site WHERE userid = ?", (assigned_assistant_id,)
                )
            return [_site_to_dict(r) for r in rows]

    def get(self, site_id: str) -> Record | None:
        with connect() as c:
            row = c.execute(
                "SELECT * FROM site WHERE siteid = ?", (site_id,)
            ).fetchone()
            return _site_to_dict(row) if row else None

    def _to_cols(self, record: Record) -> dict[str, Any]:
        cols: dict[str, Any] = {}
        for app, col in _SITE_MAP.items():
            if app not in record:
                continue
            cols[col] = record[app]
        return cols

    def update(self, site_id: str, changes: Record) -> Record | None:
        cols = self._to_cols(changes)
        if cols:
            assignments = ", ".join(f"{col} = ?" for col in cols)
            with connect() as c:
                cur = c.execute(
                    f"UPDATE site SET {assignments} WHERE siteid = ?",
                    (*cols.values(), site_id),
                )
                if cur.rowcount == 0:
                    return None
        return self.get(site_id)

    def add(self, record: Record) -> Record:
        cols = self._to_cols(record)
        columns = ", ".join(cols)
        placeholders = ", ".join("?" for _ in cols)
        with connect() as c:
            c.execute(
                f"INSERT INTO site ({columns}) VALUES ({placeholders})",
                tuple(cols.values()),
            )
        return self.get(record["site_id"])

    def delete(self, site_id: str) -> bool:
        with connect() as c:
            cur = c.execute("DELETE FROM site WHERE siteid = ?", (site_id,))
            return cur.rowcount > 0


class _SiteScopedRepo:
    """Read/insert helpers for JSON-blob tables filtered by site_id."""

    _table = ""

    def list(self, site_id: str | None = None) -> list[Record]:
        with connect() as c:
            if site_id:
                rows = c.execute(
                    f"SELECT data FROM {self._table} WHERE site_id = ?", (site_id,)
                )
            else:
                rows = c.execute(f"SELECT data FROM {self._table}")
            return [loads(r["data"]) for r in rows]

    def add(self, record: Record) -> Record:
        with connect() as c:
            c.execute(
                f"INSERT INTO {self._table} (id, site_id, data) VALUES (?, ?, ?)",
                (record["id"], record["site_id"], dumps(record)),
            )
        return record

    def delete(self, record_id: str) -> bool:
        with connect() as c:
            cur = c.execute(
                f"DELETE FROM {self._table} WHERE id = ?", (record_id,)
            )
            return cur.rowcount > 0


class SqliteReportRepository(_SiteScopedRepo, ReportRepository):
    _table = "reports"

    def get(self, report_id: str) -> Record | None:
        with connect() as c:
            row = c.execute(
                "SELECT data FROM reports WHERE id = ?", (report_id,)
            ).fetchone()
            return loads(row["data"]) if row else None

    def update(self, report_id: str, changes: Record) -> Record | None:
        current = self.get(report_id)
        if current is None:
            return None
        current.update(changes)
        with connect() as c:
            c.execute(
                "UPDATE reports SET data = ? WHERE id = ?", (dumps(current), report_id)
            )
        return current



_VOICE_MAP = {
    "id": "voiceid",
    "site_id": "siteid",
    "user_id": "userid",
    "transcript": "transcript",
    "file_path": "file_path",
    "created_at": "created_at",
}
_PICTURE_MAP = {
    "id": "pictureid",
    "site_id": "siteid",
    "user_id": "userid",
    "file_path": "file_path",
    "caption": "caption",
    "created_at": "created_at",
}


class _MappedMediaRepo:
    """Read/insert helper for the normalised media tables (voice_notes,
    pictures). Translates between DB columns and application dict keys."""

    _table = ""
    _map: dict[str, str] = {}
    _site_col = "siteid"

    def _to_dict(self, row) -> Record:
        return {app: row[col] for app, col in self._map.items()}

    def list(self, site_id: str | None = None) -> list[Record]:
        with connect() as c:
            if site_id:
                rows = c.execute(
                    f"SELECT * FROM {self._table} WHERE {self._site_col} = ?",
                    (site_id,),
                )
            else:
                rows = c.execute(f"SELECT * FROM {self._table}")
            return [self._to_dict(r) for r in rows]

    def get(self, record_id: str) -> Record | None:
        id_col = self._map["id"]
        with connect() as c:
            row = c.execute(
                f"SELECT * FROM {self._table} WHERE {id_col} = ?", (record_id,)
            ).fetchone()
            return self._to_dict(row) if row else None

    def add(self, record: Record) -> Record:
        cols = {col: record.get(app) for app, col in self._map.items()}
        columns = ", ".join(cols)
        placeholders = ", ".join("?" for _ in cols)
        with connect() as c:
            c.execute(
                f"INSERT INTO {self._table} ({columns}) VALUES ({placeholders})",
                tuple(cols.values()),
            )
        return dict(record)

    def delete(self, record_id: str) -> bool:
        id_col = self._map["id"]
        with connect() as c:
            cur = c.execute(
                f"DELETE FROM {self._table} WHERE {id_col} = ?", (record_id,)
            )
            return cur.rowcount > 0


class SqliteVoiceNoteRepository(_MappedMediaRepo, VoiceNoteRepository):
    _table = "voice_notes"
    _map = _VOICE_MAP


class SqlitePictureRepository(_MappedMediaRepo, PictureRepository):
    _table = "pictures"
    _map = _PICTURE_MAP
