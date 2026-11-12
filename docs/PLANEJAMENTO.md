# Documentação de Planejamento — Fase 1

**Repositório:** https://github.com/Cordeid/devops-fase1

## 1. Descrição do projeto

O projeto é uma API web simples de lista de tarefas, escrita em Python com Flask e empacotada em container Docker. A aplicação em si é pequena de propósito: o foco do trabalho não é a regra de negócio, e sim o caminho que o código percorre do commit até um servidor na nuvem, de forma automatizada, testada e reproduzível.

Endpoints disponíveis:

| Método | Rota      | Função                                   |
|--------|-----------|------------------------------------------|
| GET    | `/`       | Mensagem de boas-vindas                  |
| GET    | `/health` | Verificação de saúde (usada no pipeline) |
| GET    | `/tasks`  | Lista as tarefas                         |
| POST   | `/tasks`  | Cria uma tarefa (campo `title` obrigatório) |

## 2. Objetivos

- Garantir que todo código enviado ao repositório seja verificado automaticamente (lint, testes e build) antes de ser considerado pronto.
- Detectar erros cedo, a cada push ou pull request, em vez de descobrir problemas só na hora da implantação.
- Descrever toda a infraestrutura em código, para que o ambiente possa ser criado, destruído e recriado com o mesmo resultado.
- Deixar a base preparada para a Fase 2 (entrega contínua e deploy automatizado).

## 3. Requisitos

**Funcionais**
- RF01 — A API deve responder em `/health` com status 200 quando estiver no ar.
- RF02 — A API deve permitir listar e cadastrar tarefas.
- RF03 — A API deve recusar o cadastro de tarefa sem título (status 400).

**Não funcionais**
- RNF01 — Código versionado no GitHub, com branch principal `main`.
- RNF02 — Pipeline de CI executado automaticamente a cada push e pull request na `main`.
- RNF03 — Testes automatizados com relatório de cobertura.
- RNF04 — Aplicação empacotada em imagem Docker.
- RNF05 — Infraestrutura provisionada com Terraform na AWS (região us-east-1, ambiente AWS Academy Learner Lab).
- RNF06 — Nenhuma credencial gravada no repositório.

## 4. Plano de integração contínua

**Ferramenta:** GitHub Actions (arquivo `.github/workflows/ci.yml`).

**Gatilhos:** push e pull request na branch `main`.

**Fluxo de trabalho da equipe**
1. O desenvolvedor cria uma branch a partir da `main` para cada mudança.
2. Faz commits pequenos e frequentes.
3. Abre um pull request; o pipeline roda automaticamente.
4. A mudança só entra na `main` com o pipeline verde.

**Etapas do pipeline**

| Job          | O que faz                                                                 | Falha quando                       |
|--------------|---------------------------------------------------------------------------|------------------------------------|
| `testes`     | Instala dependências, roda o `flake8` (padrão de código) e o `pytest` com cobertura | Há erro de estilo ou teste quebrado |
| `build`      | Constrói a imagem Docker e sobe o container, chamando `/health` (smoke test) | A imagem não builda ou a app não responde |
| `terraform`  | Roda `terraform fmt`, `init` e `validate` nos scripts de infraestrutura   | O código de IaC está mal formatado ou inválido |

O job `build` só começa se `testes` passar. O `terraform` roda em paralelo, já que não depende da aplicação.

**Testes automatizados (arquivo `tests/test_app.py`)**
- Rota inicial responde 200.
- `/health` retorna `{"status": "ok"}`.
- Lista de tarefas começa vazia.
- Criação de tarefa retorna 201 e a tarefa aparece na listagem.
- Tarefa sem título é rejeitada com 400.

**Feedback:** o resultado aparece na aba *Actions* do GitHub e no próprio pull request.

## 5. Especificação da infraestrutura

Provisionada com Terraform (pasta `infra/terraform`).

| Recurso | Tipo / configuração | Finalidade |
|---------|---------------------|------------|
| Rede | VPC e sub-rede padrão da conta | Simplificar o ambiente do laboratório |
| Security Group | Entrada 5000/TCP (aberta) e 22/TCP (configurável); saída liberada | Acesso à aplicação e SSH |
| Instância EC2 | Ubuntu 22.04, `t3.micro`, IP público, chave `vockey` | Servidor da aplicação |
| User data | Instala Docker e Git, clona o repositório e sobe o container | Configuração automática do servidor |
| Bucket S3 | Versionamento ativo e acesso público bloqueado | Guardar artefatos do projeto |

**Arquivos**
- `providers.tf` — versão do Terraform e provedores (AWS e Random).
- `variables.tf` — parâmetros (região, tipo de instância, chave, URL do repositório, IP liberado para SSH).
- `main.tf` — recursos.
- `outputs.tf` — IP público, URL da aplicação e nome do bucket.
- `user_data.sh` — script executado na primeira inicialização da EC2.

**Decisões e limitações**
- A região é us-east-1 porque o Learner Lab só permite us-east-1 e us-west-2.
- As credenciais do Learner Lab são temporárias (expiram ao fim da sessão). Por isso, nesta fase o pipeline apenas **valida** o Terraform; o `apply` é feito manualmente pelo terminal do laboratório. A aplicação automática fica para a Fase 2.
- O estado do Terraform é local. Em um ambiente real, o recomendado seria guardar o estado em um bucket S3 com bloqueio.
- Para economizar créditos, os recursos devem ser destruídos (`terraform destroy`) depois da demonstração.
