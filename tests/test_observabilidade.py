"""Testes de monitoramento (métricas) e logging."""
import io
import json
import logging

from app.logging_config import JsonFormatter


def test_metrics_expoe_formato_prometheus(client):
    client.get("/health")
    r = client.get("/metrics")
    assert r.status_code == 200
    assert r.content_type.startswith("text/plain")
    texto = r.get_data(as_text=True)
    assert "http_requests_total" in texto
    assert "http_request_duration_seconds" in texto
    assert 'app_info{env="test",version="teste"}' in texto


def test_metrica_de_tarefas_atualiza(client):
    client.post("/tasks", json={"title": "a"})
    client.post("/tasks", json={"title": "b"})
    texto = client.get("/metrics").get_data(as_text=True)
    assert "tasks_total 2.0" in texto


def test_log_em_json(client):
    stream = io.StringIO()
    handler = logging.StreamHandler(stream)
    handler.setFormatter(JsonFormatter())
    logger = logging.getLogger("app")
    logger.addHandler(handler)
    try:
        client.get("/health")
    finally:
        logger.removeHandler(handler)
    registro = json.loads(stream.getvalue().strip().splitlines()[-1])
    assert registro["message"] == "request"
    assert registro["path"] == "/health"
    assert registro["status"] == 200
    assert registro["level"] == "INFO"
    assert "duration_ms" in registro
    assert "timestamp" in registro
