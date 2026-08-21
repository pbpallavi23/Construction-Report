from __future__ import annotations

import time

from flask import Flask, g, request

from app.core.logging import get_logger

logger = get_logger("http")


def register_request_logging(app: Flask) -> None:
    @app.before_request
    def _start_timer() -> None:
        g._start_time = time.perf_counter()

    @app.after_request
    def _log_request(response):
        start = getattr(g, "_start_time", None)
        elapsed_ms = (time.perf_counter() - start) * 1000 if start else 0.0
        response.headers["X-Process-Time-ms"] = f"{elapsed_ms:.1f}"
        logger.info(
            "%s %s -> %s (%.1f ms)",
            request.method,
            request.path,
            response.status_code,
            elapsed_ms,
        )
        return response
