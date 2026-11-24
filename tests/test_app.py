"""Testes unitários das rotas da API."""


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    body = r.get_json()
    assert "Hello" in body["message"]
    assert body["version"] == "teste"


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok", "version": "teste", "env": "test"}


def test_lista_vazia(client):
    assert client.get("/tasks").get_json() == []


def test_cria_tarefa(client):
    r = client.post("/tasks", json={"title": "Configurar pipeline"})
    assert r.status_code == 201
    assert r.get_json() == {"id": 1, "title": "Configurar pipeline", "done": False}
    assert len(client.get("/tasks").get_json()) == 1


def test_rejeita_tarefa_sem_titulo(client):
    assert client.post("/tasks", json={}).status_code == 400


def test_rejeita_titulo_em_branco(client):
    assert client.post("/tasks", json={"title": "   "}).status_code == 400


def test_rejeita_titulo_longo(client):
    assert client.post("/tasks", json={"title": "x" * 201}).status_code == 400


def test_rejeita_corpo_invalido(client):
    r = client.post("/tasks", data="isso não é json", content_type="text/plain")
    assert r.status_code == 400


def test_rota_inexistente(client):
    r = client.get("/nao-existe")
    assert r.status_code == 404
    assert "error" in r.get_json()


def test_cabecalhos_de_seguranca(client):
    r = client.get("/health")
    assert r.headers["X-Content-Type-Options"] == "nosniff"
    assert r.headers["X-Frame-Options"] == "DENY"
    assert "default-src 'none'" in r.headers["Content-Security-Policy"]
    assert r.headers["Cache-Control"] == "no-store"
