#!/usr/bin/env bash
# Teste de fumaça (smoke test) contra uma instância da aplicação já no ar.
# Uso: ./scripts/smoke-test.sh http://localhost:5000 [versao-esperada]
set -euo pipefail

BASE_URL="${1:?informe a URL base, ex.: http://localhost:5000}"
EXPECTED_VERSION="${2:-}"

passo() { printf '  - %s... ' "$1"; }
ok()    { echo "OK"; }
falha() { echo "FALHOU: $1"; exit 1; }

echo "Smoke test em ${BASE_URL}"

passo "GET /health responde 200"
health=$(curl -fsS "${BASE_URL}/health") || falha "sem resposta"
echo "${health}" | grep -q '"status":"ok"' || falha "corpo inesperado: ${health}"
ok

if [ -n "${EXPECTED_VERSION}" ]; then
  passo "versão publicada é ${EXPECTED_VERSION}"
  echo "${health}" | grep -q "\"version\":\"${EXPECTED_VERSION}\"" || falha "recebido: ${health}"
  ok
fi

passo "POST /tasks cria tarefa (201)"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE_URL}/tasks" \
  -H 'Content-Type: application/json' -d '{"title":"tarefa do smoke test"}')
[ "${code}" = "201" ] || falha "status ${code}"
ok

passo "POST /tasks sem título é recusado (400)"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "${BASE_URL}/tasks" \
  -H 'Content-Type: application/json' -d '{}')
[ "${code}" = "400" ] || falha "status ${code}"
ok

passo "GET /tasks lista a tarefa criada"
curl -fsS "${BASE_URL}/tasks" | grep -q "tarefa do smoke test" || falha "tarefa não encontrada"
ok

passo "GET /metrics expõe métricas Prometheus"
curl -fsS "${BASE_URL}/metrics" | grep -q "http_requests_total" || falha "métricas ausentes"
ok

echo "Smoke test concluído com sucesso."
