#!/usr/bin/env bash
# Deploy com Docker Compose: API + Prometheus + Grafana num único servidor.
#
# Uso: ./scripts/deploy-compose.sh
#      APP_IMAGE=ghcr.io/cordeid/devops-fase1:sha-abc1234 ./scripts/deploy-compose.sh
#      BUILD_LOCAL=1 ./scripts/deploy-compose.sh      (constrói a imagem a partir do código)
set -euo pipefail

DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "${DIR}"
export APP_IMAGE="${APP_IMAGE:-ghcr.io/cordeid/devops-fase1:latest}"

if [ "${BUILD_LOCAL:-0}" = "1" ]; then
  echo "==> Construindo a imagem localmente"
  docker compose build app
else
  echo "==> Baixando ${APP_IMAGE}"
  docker compose pull app
fi

echo "==> Subindo os serviços"
docker compose up -d

echo "==> Aguardando a API responder"
for _ in $(seq 1 30); do
  curl -fs http://localhost:5000/health >/dev/null 2>&1 && break
  sleep 2
done

bash "${DIR}/scripts/smoke-test.sh" http://localhost:5000
docker compose ps
echo
echo "API:        http://localhost:5000"
echo "Prometheus: http://localhost:9090"
echo "Grafana:    http://localhost:3000 (painel 'API de Tarefas - DevOps')"
