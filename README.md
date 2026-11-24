# devops-fase1

![CI/CD](https://github.com/Cordeid/devops-fase1/actions/workflows/ci-cd.yml/badge.svg)

API de tarefas em Flask usada como base do projeto da disciplina **DevOps na Prática** (PUCRS).
O foco não é a regra de negócio, e sim o caminho automatizado do commit até a produção.

| Ambiente | Onde roda | Como chega lá |
|---|---|---|
| Homologação | Kubernetes temporário (kind) dentro do GitHub Actions | Automático a cada push na `main` |
| Produção | Render.com (imagem Docker) | Automático, só depois da homologação passar |
| Alternativo | EC2 na AWS (Terraform + Ansible) | Manual, pelo AWS Academy |

## Fluxo CI/CD

```
push/PR ─► CI: lint + 15 testes (cobertura ≥ 90%) ─┐
           CI: Bandit (SAST) + pip-audit ──────────┼─► CD: build da imagem ─► smoke test ─► Trivy ─► GHCR
           CI: Terraform + Ansible ────────────────┘                                                 │
                                                       produção (Render) ◄─ ZAP ◄─ homologação (k8s) ◄┘
```

Detalhes em [`docs/FASE2.md`](docs/FASE2.md). Planejamento da Fase 1 em [`docs/PLANEJAMENTO.md`](docs/PLANEJAMENTO.md).

## Estrutura

```
app/                    API Flask (rotas, config por variáveis, logs JSON, métricas)
tests/                  testes unitários, de observabilidade e de configuração
.github/workflows/      pipeline CI/CD
Dockerfile              imagem multi-stage, usuário não-root, healthcheck
docker-compose.yml      API + Prometheus + Grafana
k8s/                    manifests Kubernetes (deployment, service, configmap, HPA)
scripts/                deploy (compose, k8s, Render), rollback e smoke test
monitoring/             Prometheus (coleta e alertas) e Grafana (painel)
deploy/ansible/         playbook de configuração do servidor
infra/terraform/        infraestrutura AWS (EC2, security group, S3)
render.yaml             blueprint do serviço de produção
```

## Endpoints

| Método | Rota | Descrição |
|---|---|---|
| GET | `/` | Boas-vindas, versão e ambiente |
| GET | `/health` | Saúde da aplicação (usado em probes e no deploy) |
| GET | `/metrics` | Métricas no formato Prometheus |
| GET | `/tasks` | Lista as tarefas |
| POST | `/tasks` | Cria tarefa (`{"title": "..."}`) |

## Rodando

```bash
# Desenvolvimento
pip install -r requirements-dev.txt
pytest -v --cov=app
python wsgi.py                               # http://localhost:5000

# Ambiente completo com monitoramento
BUILD_LOCAL=1 ./scripts/deploy-compose.sh    # API :5000, Prometheus :9090, Grafana :3000

# Kubernetes (qualquer cluster com kubectl configurado)
./scripts/deploy-k8s.sh ghcr.io/cordeid/devops-fase1:latest
./scripts/rollback-k8s.sh                    # volta para a versão anterior
```

## Configuração

Toda configuração vem de variáveis de ambiente (a mesma imagem roda em qualquer ambiente):

| Variável | Padrão | Uso |
|---|---|---|
| `APP_ENV` | `development` | Nome do ambiente |
| `APP_VERSION` | `dev` | Definida no build com o hash do commit |
| `LOG_LEVEL` | `INFO` | Nível dos logs |
| `PORT` | `5000` | Porta HTTP (o Render define a sua) |
