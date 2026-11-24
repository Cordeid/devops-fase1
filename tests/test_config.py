"""Testes de gerenciamento de configuração por variáveis de ambiente."""
import importlib


def test_config_le_variaveis_de_ambiente(monkeypatch):
    monkeypatch.setenv("APP_ENV", "producao")
    monkeypatch.setenv("APP_VERSION", "abc1234")
    monkeypatch.setenv("LOG_LEVEL", "warning")
    import app.config as config
    importlib.reload(config)
    assert config.Config.APP_ENV == "producao"
    assert config.Config.APP_VERSION == "abc1234"
    assert config.Config.LOG_LEVEL == "WARNING"


def test_config_tem_valores_padrao(monkeypatch):
    for var in ("APP_ENV", "APP_VERSION", "LOG_LEVEL"):
        monkeypatch.delenv(var, raising=False)
    import app.config as config
    importlib.reload(config)
    assert config.Config.APP_ENV == "development"
    assert config.Config.APP_VERSION == "dev"
