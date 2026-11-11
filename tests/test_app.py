import pytest

from app import create_app


@pytest.fixture
def client():
    app = create_app()
    app.config["TESTING"] = True
    with app.test_client() as c:
        yield c


def test_index(client):
    r = client.get("/")
    assert r.status_code == 200
    assert "Hello" in r.get_json()["message"]


def test_health(client):
    r = client.get("/health")
    assert r.status_code == 200
    assert r.get_json() == {"status": "ok"}


def test_lista_vazia(client):
    assert client.get("/tasks").get_json() == []


def test_cria_tarefa(client):
    r = client.post("/tasks", json={"title": "Configurar pipeline"})
    assert r.status_code == 201
    assert r.get_json()["id"] == 1
    assert len(client.get("/tasks").get_json()) == 1


def test_rejeita_tarefa_sem_titulo(client):
    r = client.post("/tasks", json={})
    assert r.status_code == 400
