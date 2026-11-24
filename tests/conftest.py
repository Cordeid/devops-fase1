import pytest

from app import create_app


@pytest.fixture
def app():
    return create_app({"TESTING": True, "APP_VERSION": "teste", "APP_ENV": "test"})


@pytest.fixture
def client(app):
    with app.test_client() as c:
        yield c
