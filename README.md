# devops-fase1

![CI](https://github.com/Cordeid/devops-fase1/actions/workflows/ci.yml/badge.svg)

API de tarefas em Flask usada como base do projeto da disciplina DevOps na Prática.

## Estrutura

```
app/                  código da aplicação
tests/                testes automatizados (pytest)
.github/workflows/    pipeline de CI (GitHub Actions)
infra/terraform/      infraestrutura como código
docs/PLANEJAMENTO.md  documentação de planejamento
Dockerfile
```

## Rodando localmente

```bash
pip install -r requirements-dev.txt
pytest -v
python wsgi.py        # http://localhost:5000
```

## Provisionando a infraestrutura (AWS Academy Learner Lab)

```bash
cd infra/terraform
cp terraform.tfvars.example terraform.tfvars   # edite a repo_url
terraform init
terraform plan
terraform apply
# ao terminar:
terraform destroy
```
