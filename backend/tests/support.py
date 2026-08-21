"""Shared setup for the test suite.

Import this module FIRST (before importing anything from `app`) in every
test file, e.g.:

    from tests import support
    from app.services import auth_service

This sets safe, isolated environment variables (temp upload dir, disabled
AI autofill, throwaway JWT secret, etc.) before the `app.core.config`
singleton is created, and exposes helpers for running the same test logic
against BOTH persistence backends (in-memory and SQLite) without needing
pytest or any third-party dependency - everything here is stdlib
`unittest`.
"""
from __future__ import annotations

import os
import shutil
import sys
import tempfile
import unittest
from pathlib import Path


_BACKEND_DIR = Path(__file__).resolve().parents[1]
if str(_BACKEND_DIR) not in sys.path:
    sys.path.insert(0, str(_BACKEND_DIR))


_TEST_UPLOAD_DIR = tempfile.mkdtemp(prefix="baxall_test_uploads_")
os.environ["UPLOAD_DIR"] = _TEST_UPLOAD_DIR
os.environ.setdefault("PERSISTENCE_BACKEND", "memory")
os.environ.setdefault("DATABASE_PATH", os.path.join(_TEST_UPLOAD_DIR, "unused.db"))
os.environ.setdefault("DEBUG", "false")
os.environ.setdefault("AI_AUTOFILL_ENABLED", "false")
os.environ.setdefault("MOCK_OCR_DELAY", "0")
os.environ.setdefault("MOCK_AI_DELAY", "0")
os.environ.setdefault("JWT_SECRET_KEY", "test-only-secret-do-not-use")
os.environ.setdefault("ACCESS_TOKEN_EXPIRE_MINUTES", "720")
os.environ.setdefault("CORS_ORIGINS", "*")

import logging

from app.core.config import settings
from app.core.logging import configure_logging
from app.core.security import hash_password




configure_logging(debug=False)
logging.getLogger("baxall").setLevel(logging.WARNING)
logging.getLogger().setLevel(logging.WARNING)
from app.core.utils import new_id
from app.persistence.memory.builder import build_memory_registry
from app.persistence.registry import RepositoryRegistry
from app.persistence.sqlite import build_sqlite_registry
from app.services import (
    assistant_service,
    auth_service,
    incident_report_service,
    picture_service,
    site_service,
    speech_service,
)




SERVICE_MODULES = [
    assistant_service,
    auth_service,
    incident_report_service,
    picture_service,
    site_service,
    speech_service,
]

BACKENDS = ("memory", "sqlite")


def _make_registry(backend: str) -> RepositoryRegistry:
    if backend == "memory":
        return build_memory_registry()
    if backend == "sqlite":
        fd, path = tempfile.mkstemp(suffix=".db", prefix="baxall_test_")
        os.close(fd)
        os.remove(path)
        settings.DATABASE_PATH = path
        return build_sqlite_registry()
    raise ValueError(f"Unknown backend: {backend!r}")


class RepositoryBackedTestCase(unittest.TestCase):
    """Base class for tests that need a repository registry.

    Call `self.new_registry(backend)` in setUp to get a fresh, isolated
    registry and have it patched into every service module for the
    duration of the test.
    """

    backend: str = "memory"

    def setUp(self) -> None:
        super().setUp()
        self.registry = self.new_registry(self.backend)

    def new_registry(self, backend: str) -> RepositoryRegistry:
        registry = _make_registry(backend)
        for module in SERVICE_MODULES:
            original = module.repositories
            module.repositories = registry
            self.addCleanup(setattr, module, "repositories", original)
        return registry



    def make_assistant(
        self,
        email: str = "j.smith@baxall.co.uk",
        password: str = "baxall123",
        full_name: str = "Jamie Smith",
        role: str = "Site Engineer",
    ) -> dict:
        record = {
            "assistant_id": new_id("user"),
            "full_name": full_name,
            "email": email,
            "password_hash": hash_password(password),
            "role": role,
            "phone": None,
            "avatar_url": None,
        }
        return self.registry.assistants.add(record)

    def make_site(
        self,
        site_name: str = "Riverside Tower",
        address: str = "1 Riverside Way, London",
        assigned_assistant_id: str | None = None,
        status: str = "active",
    ) -> dict:
        record = {
            "site_id": new_id("site"),
            "site_name": site_name,
            "site_code": None,
            "address": address,
            "status": status,
            "assigned_assistant_id": assigned_assistant_id,
            "phase": None,
            "latitude": None,
            "longitude": None,
        }
        return self.registry.sites.add(record)


def parametrize_over_backends(mixin_cls: type, module_name: str) -> dict:
    """Given a plain mixin class (NOT a TestCase - just test_* methods) that
    assumes `self.registry` / `self.backend` from RepositoryBackedTestCase,
    produce a dict of {name: TestCase subclass} - one per backend - suitable
    for injecting into module globals so `unittest discover` picks each one
    up separately (e.g. `AssistantRepositoryTests_Memory`,
    `AssistantRepositoryTests_Sqlite`).

    `mixin_cls` must NOT itself subclass unittest.TestCase, or it would also
    get collected (and run) directly under the default backend, duplicating
    every test.
    """
    assert not issubclass(mixin_cls, unittest.TestCase), (
        f"{mixin_cls.__name__} must be a plain mixin, not a TestCase itself "
        "(it would get double-collected by unittest discover)."
    )
    variants = {}
    for backend in BACKENDS:
        name = f"{mixin_cls.__name__}_{backend.capitalize()}"
        cls = type(name, (mixin_cls, RepositoryBackedTestCase), {"backend": backend})
        cls.__module__ = module_name
        variants[name] = cls
    return variants


def cleanup_upload_dir() -> None:
    shutil.rmtree(_TEST_UPLOAD_DIR, ignore_errors=True)
