from __future__ import annotations

from flask import Flask, request, send_from_directory

from app.admin import admin_bp
from app.api.v1.router import blueprints
from app.core.config import settings
from app.core.exceptions import register_error_handlers
from app.core.logging import configure_logging, get_logger
from app.middleware.request_logging import register_request_logging
from app.persistence import get_repositories

configure_logging(debug=settings.DEBUG)
logger = get_logger(__name__)


def _register_cors(app: Flask) -> None:
    allowed = settings.CORS_ORIGINS

    @app.after_request
    def _apply_cors(response):
        origin = request.headers.get("Origin")
        if "*" in allowed:
            response.headers["Access-Control-Allow-Origin"] = origin or "*"
        elif origin in allowed:
            response.headers["Access-Control-Allow-Origin"] = origin
        response.headers["Vary"] = "Origin"
        response.headers["Access-Control-Allow-Credentials"] = "true"
        response.headers["Access-Control-Allow-Methods"] = "GET, POST, PUT, PATCH, DELETE, OPTIONS"
        response.headers["Access-Control-Allow-Headers"] = "Authorization, Content-Type"
        response.headers["Access-Control-Expose-Headers"] = "X-Process-Time-ms"
        return response


def create_app() -> Flask:
    app = Flask(__name__)

    app.secret_key = settings.JWT_SECRET_KEY

    _register_cors(app)
    register_request_logging(app)
    register_error_handlers(app)


    app.register_blueprint(admin_bp)

    def health():
        return {
            "status": "ok",
            "app": settings.APP_NAME,
            "version": settings.VERSION,
            "environment": settings.APP_ENV,
        }

    app.add_url_rule("/", "root_health", health)
    app.add_url_rule("/health", "health", health)


    def uploaded_file(relpath: str):
        return send_from_directory(settings.UPLOAD_DIR, relpath)

    app.add_url_rule("/uploads/<path:relpath>", "uploaded_file", uploaded_file)

    for blueprint in blueprints:
        app.register_blueprint(blueprint, url_prefix=settings.API_V1_PREFIX)


    get_repositories()
    logger.info(
        "%s v%s ready (%s) [%s backend]",
        settings.APP_NAME,
        settings.VERSION,
        settings.APP_ENV,
        settings.PERSISTENCE_BACKEND,
    )
    return app


app = create_app()


if __name__ == "__main__":
    app.run(host=settings.HOST, port=settings.PORT, debug=settings.DEBUG)
