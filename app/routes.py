from flask import Blueprint, Response, current_app, jsonify, request
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest

from app.metrics import TASKS

bp = Blueprint("api", __name__)


@bp.get("/")
def index():
    return jsonify(
        message="Hello DevOps - Fase 2",
        version=current_app.config["APP_VERSION"],
        env=current_app.config["APP_ENV"],
    )


@bp.get("/health")
def health():
    return jsonify(
        status="ok",
        version=current_app.config["APP_VERSION"],
        env=current_app.config["APP_ENV"],
    ), 200


@bp.get("/metrics")
def metrics():
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


@bp.get("/tasks")
def list_tasks():
    return jsonify(current_app.config["TASKS"]), 200


@bp.post("/tasks")
def create_task():
    data = request.get_json(silent=True) or {}
    title = str(data.get("title", "")).strip()
    if not title:
        return jsonify(error="O campo 'title' é obrigatório"), 400
    if len(title) > 200:
        return jsonify(error="O campo 'title' aceita no máximo 200 caracteres"), 400

    tasks = current_app.config["TASKS"]
    task = {"id": len(tasks) + 1, "title": title, "done": False}
    tasks.append(task)
    TASKS.set(len(tasks))
    return jsonify(task), 201


@bp.app_errorhandler(404)
def not_found(_error):
    return jsonify(error="Recurso não encontrado"), 404
