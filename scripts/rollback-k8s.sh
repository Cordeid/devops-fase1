#!/usr/bin/env bash
# Volta o Deployment para a versão anterior (ou para uma revisão específica).
# Uso: ./scripts/rollback-k8s.sh [revisao]
set -euo pipefail
NAMESPACE="devops"
DEPLOYMENT="devops-app"

if [ -n "${1:-}" ]; then
  echo "==> Rollback para a revisão $1"
  kubectl -n "${NAMESPACE}" rollout undo "deployment/${DEPLOYMENT}" --to-revision="$1"
else
  echo "==> Rollback para a revisão anterior"
  kubectl -n "${NAMESPACE}" rollout undo "deployment/${DEPLOYMENT}" || {
    echo "Não há revisão anterior (primeiro deploy)."; exit 0; }
fi
kubectl -n "${NAMESPACE}" rollout status "deployment/${DEPLOYMENT}" --timeout=120s
