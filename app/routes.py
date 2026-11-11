from flask import Blueprint, current_app, jsonify, request

bp = Blueprint("api", __name__)


@bp.get("/")
def index():
    return jsonify(message="Hello DevOps - Fase 1")


@bp.get("/health")
def health():
    return jsonify(status="ok"), 200


@bp.get("/tasks")
def list_tasks():
    return jsonify(current_app.config["TASKS"]), 200


@bp.post("/tasks")
def create_task():
    data = request.get_json(silent=True) or {}
    title = str(data.get("title", "")).strip()
    if not title:
        return jsonify(error="O campo 'title' é obrigatório"), 400

    tasks = current_app.config["TASKS"]
    task = {"id": len(tasks) + 1, "title": title, "done": False}
    tasks.append(task)
    return jsonify(task), 201
