# ---------------------------------------------------------------
# Estágio 1 (builder): instala as dependências num ambiente virtual
# ---------------------------------------------------------------
FROM python:3.12-slim AS builder

WORKDIR /build
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip \
 && pip install --no-cache-dir -r requirements.txt

# ---------------------------------------------------------------
# Estágio 2 (runtime): imagem final enxuta, sem ferramentas de build
# ---------------------------------------------------------------
FROM python:3.12-slim AS runtime

ARG APP_VERSION=dev
LABEL org.opencontainers.image.title="devops-fase1" \
      org.opencontainers.image.description="API de tarefas - projeto DevOps na Prática" \
      org.opencontainers.image.source="https://github.com/Cordeid/devops-fase1" \
      org.opencontainers.image.version="${APP_VERSION}"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH" \
    APP_VERSION=${APP_VERSION} \
    APP_ENV=production \
    PORT=5000

# Usuário sem privilégios: o container nunca roda como root
RUN groupadd --system app && useradd --system --gid app --no-create-home app

WORKDIR /app
COPY --from=builder /opt/venv /opt/venv
COPY --chown=app:app app ./app
COPY --chown=app:app wsgi.py .

USER app
EXPOSE 5000

# O Docker marca o container como "unhealthy" se /health parar de responder
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen(f'http://127.0.0.1:{os.environ.get(\"PORT\",\"5000\")}/health', timeout=2)" || exit 1

# 1 worker com threads: as tarefas ficam em memória, então um único processo
# mantém os dados e as métricas consistentes (ver limitações no relatório)
CMD ["sh", "-c", "exec gunicorn --bind 0.0.0.0:${PORT} --workers 1 --threads 4 --error-logfile - wsgi:app"]
