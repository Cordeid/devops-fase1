#!/usr/bin/env bash
# Deploy em produção no Render.com usando a imagem já testada na homologação.
#
# Variáveis:
#   RENDER_DEPLOY_HOOK_URL  deploy hook do serviço (secret do GitHub, nunca no código)
#   RENDER_APP_URL          URL pública do serviço, ex.: https://devops-fase1.onrender.com
#   IMAGE                   imagem a publicar, ex.: ghcr.io/cordeid/devops-fase1:sha-abc1234
#   EXPECTED_VERSION        versão que /health deve devolver depois do deploy
set -euo pipefail

: "${RENDER_DEPLOY_HOOK_URL:?defina o secret RENDER_DEPLOY_HOOK_URL}"
: "${RENDER_APP_URL:?defina a variável RENDER_APP_URL}"
: "${IMAGE:?defina IMAGE}"
: "${EXPECTED_VERSION:?defina EXPECTED_VERSION}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Disparando o deploy de ${IMAGE} no Render"
encoded_image=$(python3 -c 'import sys, urllib.parse; print(urllib.parse.quote(sys.argv[1], safe=""))' "${IMAGE}")
curl -fsS -X POST "${RENDER_DEPLOY_HOOK_URL}&imgURL=${encoded_image}" >/dev/null
echo "    deploy solicitado"

echo "==> Aguardando a versão ${EXPECTED_VERSION} em ${RENDER_APP_URL} (até 15 min)"
for i in $(seq 1 90); do
  body=$(curl -s --max-time 20 "${RENDER_APP_URL}/health" || true)
  if echo "${body}" | grep -q "\"version\":\"${EXPECTED_VERSION}\""; then
    echo "    versão nova no ar após ~$((i * 10)) s"
    bash "${DIR}/scripts/smoke-test.sh" "${RENDER_APP_URL}" "${EXPECTED_VERSION}"
    exit 0
  fi
  echo "    tentativa ${i}: ainda respondendo ${body:-sem resposta}"
  sleep 10
done

echo "!! A versão ${EXPECTED_VERSION} não entrou no ar a tempo."
echo "   O Render mantém a versão anterior rodando quando o deploy falha (rollback implícito)."
exit 1
