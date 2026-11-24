"""Métricas no formato Prometheus, expostas em /metrics."""
from prometheus_client import Counter, Gauge, Histogram, Info

REQUESTS = Counter(
    "http_requests_total",
    "Total de requisições HTTP",
    ["method", "endpoint", "status"],
)
LATENCY = Histogram(
    "http_request_duration_seconds",
    "Tempo de resposta das requisições HTTP",
    ["method", "endpoint"],
)
TASKS = Gauge("tasks_total", "Quantidade de tarefas cadastradas")
APP_INFO = Info("app", "Versão e ambiente da aplicação")
