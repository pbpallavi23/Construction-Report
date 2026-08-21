from __future__ import annotations

from typing import Any

from flask import Flask, jsonify
from werkzeug.exceptions import HTTPException

from app.core.logging import get_logger

logger = get_logger(__name__)


class AppError(Exception):
    status_code: int = 400
    code: str = "app_error"

    def __init__(self, message: str, details: Any | None = None) -> None:
        super().__init__(message)
        self.message = message
        self.details = details


class NotFoundError(AppError):
    status_code = 404
    code = "not_found"


class UnauthorizedError(AppError):
    status_code = 401
    code = "unauthorized"


class ForbiddenError(AppError):
    status_code = 403
    code = "forbidden"


class ValidationAppError(AppError):
    status_code = 422
    code = "validation_error"


class ConflictError(AppError):
    status_code = 409
    code = "conflict"


def _error_body(code: str, message: str, details: Any | None = None) -> dict[str, Any]:
    return {"error": {"code": code, "message": message, "details": details}}


def register_error_handlers(app: Flask) -> None:
    @app.errorhandler(AppError)
    def _handle_app_error(exc: AppError):
        logger.info("AppError [%s]: %s", exc.code, exc.message)
        response = jsonify(_error_body(exc.code, exc.message, exc.details))
        response.status_code = exc.status_code
        return response

    @app.errorhandler(HTTPException)
    def _handle_http_error(exc: HTTPException):
        code = {
            401: "unauthorized",
            403: "forbidden",
            404: "not_found",
            405: "method_not_allowed",
        }.get(exc.code or 500, "http_error")
        response = jsonify(_error_body(code, exc.description or exc.name))
        response.status_code = exc.code or 500
        return response

    @app.errorhandler(Exception)
    def _handle_unexpected_error(exc: Exception):
        logger.exception("Unhandled error: %s", exc)
        response = jsonify(
            _error_body(
                "internal_error",
                "An unexpected error occurred. Please try again.",
            )
        )
        response.status_code = 500
        return response
