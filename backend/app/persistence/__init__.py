from __future__ import annotations

from functools import lru_cache
from typing import Callable

from app.core.config import settings
from app.core.logging import get_logger
from app.persistence.memory import build_memory_registry
from app.persistence.registry import RepositoryRegistry
from app.persistence.sqlite import build_sqlite_registry

logger = get_logger(__name__)

BackendFactory = Callable[[], RepositoryRegistry]

_BACKENDS: dict[str, BackendFactory] = {
    "memory": build_memory_registry,
    "sqlite": build_sqlite_registry,
}


def register_backend(name: str, factory: BackendFactory) -> None:
    _BACKENDS[name.strip().lower()] = factory


@lru_cache
def get_repositories() -> RepositoryRegistry:
    backend = settings.PERSISTENCE_BACKEND.strip().lower()
    factory = _BACKENDS.get(backend)
    if factory is None:
        available = ", ".join(sorted(_BACKENDS))
        raise RuntimeError(
            f"Unknown persistence backend '{backend}'. Available backends: {available}."
        )
    logger.info("Using '%s' persistence backend.", backend)
    return factory()


repositories = get_repositories()

__all__ = [
    "RepositoryRegistry",
    "get_repositories",
    "register_backend",
    "repositories",
]
