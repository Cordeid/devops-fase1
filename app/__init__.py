import time

from flask import Flask, g, request

from app.config import Config
from app.logging_config import configure_logging
from app.metrics import APP_INFO, LATENCY, REQUESTS


def create_app(config_overrides=None):
    app = Flask(__name__)
    app.config.from_object(Config)
    if config_overrides:
        app.config.update(config_overrides)
    app.config["TASKS"] = []

    logger = configure_logging(app.config["LOG_LEVEL"])
    APP_INFO.info({
        "version": app.config["APP_VERSION"],
        "env": app.config["APP_ENV"],
    })

    @app.before_request
    def start_timer():
        g.start = time.perf_counter()

    @app.after_request
    def security_headers(response):
        # Cabeçalhos recomendados pela OWASP para APIs JSON
        response.headers["X-Content-Type-Options"] = "nosniff"
        response.headers["X-Frame-Options"] = "DENY"
        response.headers["Content-Security-Policy"] = "default-src 'none'; frame-ancestors 'none'"
        response.headers["Referrer-Policy"] = "no-referrer"
        response.headers["Cache-Control"] = "no-store"
        response.headers["Cross-Origin-Resource-Policy"] = "same-origin"
        return response

    @app.after_request
    def record_request(response):
        endpoint = request.url_rule.rule if request.url_rule else "desconhecido"
        duration = time.perf_counter() - g.get("start", time.perf_counter())
        if endpoint != "/metrics":
            REQUESTS.labels(request.method, endpoint, response.status_code).inc()
            LATENCY.labels(request.method, endpoint).observe(duration)
            logger.info(
                "request",
                extra={"extra_fields": {
                    "method": request.method,
                    "path": request.path,
                    "status": response.status_code,
                    "duration_ms": round(duration * 1000, 2),
                    "version": app.config["APP_VERSION"],
                }},
            )
        return response

    from app.routes import bp
    app.register_blueprint(bp)

    logger.info("aplicação iniciada", extra={"extra_fields": {
        "env": app.config["APP_ENV"], "version": app.config["APP_VERSION"]}})
    return app
