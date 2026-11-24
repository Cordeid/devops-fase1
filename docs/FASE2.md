# Fase 2 — Entrega Contínua, Containers, Monitoramento e Segurança

## 1. Pipeline CI/CD (`.github/workflows/ci-cd.yml`)

| Job | Tipo | O que faz | Bloqueia o fluxo quando |
|---|---|---|---|
| CI · Lint e testes | CI | flake8 e pytest com cobertura mínima de 90% | estilo errado, teste quebrado ou cobertura baixa |
| CI · Segurança do código | CI | Bandit (SAST) e pip-audit (dependências) | falha de segurança média/alta ou dependência vulnerável |
| CI · Validação de IaC | CI | terraform fmt/validate e sintaxe do Ansible | IaC mal formatado ou inválido |
| CD · Build, scan e publicação | CD | build multi-stage, teste do container, Trivy, push no GHCR | imagem não sobe, smoke test falha ou CVE crítica corrigível |
| CD · Homologação | CD | cluster kind, rolling update, smoke test, OWASP ZAP | rollout ou smoke test falham (rollback automático) ou ZAP acha risco alto |
| CD · Produção | CD | deploy hook do Render com a imagem homologada e verificação da versão | versão nova não responde em 15 min (o Render mantém a anterior) |

Princípio **build once, deploy many**: a imagem `ghcr.io/cordeid/devops-fase1:sha-<commit>` é construída uma vez
e a mesma tag passa por homologação e produção. O `/health` devolve a versão, e o pipeline só considera
o deploy concluído quando a produção responde com o hash do commit.

Pull requests executam CI e build, mas não publicam nem implantam.

## 2. Containers e orquestração

- **Dockerfile** multi-stage: dependências num estágio `builder`, imagem final só com o necessário,
  usuário sem privilégios, `HEALTHCHECK` e versão gravada no build.
- **docker-compose.yml**: API + Prometheus + Grafana, com limites de CPU/memória, filesystem somente leitura
  e rotação de logs.
- **Kubernetes (`k8s/`)**: Deployment com 2 réplicas, rolling update sem indisponibilidade
  (`maxUnavailable: 0`), readiness/liveness probes, limites de recursos, `securityContext` restritivo,
  ConfigMap por ambiente, Service e HPA (2 a 5 réplicas por CPU).

### Scripts de deploy (`scripts/`)

| Script | Uso |
|---|---|
| `deploy-k8s.sh <imagem> [versão]` | aplica os manifests, troca a imagem, espera o rollout, roda o smoke test; faz rollback se algo falhar |
| `rollback-k8s.sh [revisão]` | volta o Deployment para a revisão anterior ou indicada |
| `deploy-compose.sh` | sobe API + monitoramento com Docker Compose e valida |
| `deploy-render.sh` | dispara o deploy em produção e espera a versão nova responder |
| `smoke-test.sh <url> [versão]` | valida health, versão, criação/listagem de tarefas e métricas |
| `deploy/ansible/playbook.yml` | configura um servidor (Docker) e roda a imagem desejada |

## 3. Monitoramento e logging

- `/metrics` (Prometheus): `http_requests_total` por endpoint/status, `http_request_duration_seconds`,
  `tasks_total` e `app_info` (versão/ambiente).
- `monitoring/prometheus/alerts.yml`: aplicação fora do ar, taxa de erros 5xx > 5% e latência p95 > 500 ms.
- Painel Grafana provisionado automaticamente (`monitoring/grafana/dashboards/api.json`).
- Logs em JSON (timestamp, nível, método, rota, status, duração, versão), legíveis no `docker logs`,
  `kubectl logs` e no painel de logs do Render.

## 4. Segurança (DevSecOps)

| Camada | Ferramenta / prática |
|---|---|
| Código | Bandit (SAST) |
| Dependências | pip-audit no pipeline e Dependabot semanal |
| Imagem | Trivy (bloqueia CVE crítica com correção disponível) |
| Aplicação em execução | OWASP ZAP baseline (DAST) na homologação |
| Runtime | usuário não-root, filesystem somente leitura, sem escalonamento de privilégio, capabilities removidas |
| HTTP | cabeçalhos OWASP (nosniff, CSP, X-Frame-Options, no-store) |
| Segredos | deploy hook do Render só em GitHub Secrets; nenhuma credencial no repositório |

## 5. Gerenciamento de configuração

- Configuração por variáveis de ambiente (`app/config.py`), ConfigMap no Kubernetes e `envVars` no `render.yaml`.
- Infraestrutura versionada: Terraform (AWS), `render.yaml` (Render), manifests `k8s/` e playbook Ansible.
- Linha de base: cada commit na `main` gera uma imagem imutável identificada pelo hash.
