#!/usr/bin/env bash
# Deploy da aplicação num cluster Kubernetes (usado na homologação do pipeline).
#
# Uso: ./scripts/deploy-k8s.sh <imagem> [versao-esperada]
#   ex.: ./scripts/deploy-k8s.sh ghcr.io/cordeid/devops-fase1:sha-abc1234 abc1234
#
# Passos: aplica os manifests -> troca a imagem -> espera o rolling update
#         -> roda o smoke test. Se algo falhar, faz rollback automático.
set -euo pipefail

IMAGE="${1:?informe a imagem, ex.: ghcr.io/cordeid/devops-fase1:sha-abc1234}"
EXPECTED_VERSION="${2:-}"
NAMESPACE="devops"
DEPLOYMENT="devops-app"
LOCAL_PORT="${LOCAL_PORT:-8080}"
DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "==> Aplicando manifests (namespace, configmap, service)"
kubectl apply -f "${DIR}/k8s/namespace.yaml"
kubectl apply -f "${DIR}/k8s/configmap.yaml" -f "${DIR}/k8s/service.yaml"

if kubectl get apiservice v1beta1.metrics.k8s.io >/dev/null 2>&1; then
  echo "==> metrics-server encontrado: aplicando autoscaling (HPA)"
  kubectl apply -f "${DIR}/k8s/hpa.yaml"
fi

echo "==> Aplicando o Deployment com a imagem ${IMAGE}"
# O manifest traz a imagem :latest; aqui ela é trocada pela tag exata do commit
sed "s#image: ghcr.io/cordeid/devops-fase1:latest#image: ${IMAGE}#" "${DIR}/k8s/deployment.yaml" \
  | kubectl apply -f -
kubectl -n "${NAMESPACE}" annotate "deployment/${DEPLOYMENT}" \
  kubernetes.io/change-cause="deploy ${IMAGE}" --overwrite

echo "==> Aguardando o rolling update"
if ! kubectl -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout=180s; then
  echo "!! Rollout falhou. Eventos e logs para diagnóstico:"
  kubectl -n "${NAMESPACE}" get pods -o wide || true
  kubectl -n "${NAMESPACE}" describe "deployment/${DEPLOYMENT}" | tail -20 || true
  kubectl -n "${NAMESPACE}" logs -l app=devops-app --tail=50 || true
  bash "${DIR}/scripts/rollback-k8s.sh"
  exit 1
fi

kubectl -n "${NAMESPACE}" get pods -o wide

echo "==> Smoke test via port-forward (localhost:${LOCAL_PORT})"
kubectl -n "${NAMESPACE}" port-forward "svc/${DEPLOYMENT}" "${LOCAL_PORT}:80" >/tmp/port-forward.log 2>&1 &
PF_PID=$!
trap 'kill ${PF_PID} 2>/dev/null || true' EXIT
for _ in $(seq 1 20); do
  curl -fs "http://localhost:${LOCAL_PORT}/health" >/dev/null 2>&1 && break
  sleep 1
done

if ! bash "${DIR}/scripts/smoke-test.sh" "http://localhost:${LOCAL_PORT}" "${EXPECTED_VERSION}"; then
  echo "!! Smoke test falhou após o deploy"
  bash "${DIR}/scripts/rollback-k8s.sh"
  exit 1
fi

echo "==> Deploy concluído. Histórico de versões:"
kubectl -n "${NAMESPACE}" rollout history "deployment/${DEPLOYMENT}"
