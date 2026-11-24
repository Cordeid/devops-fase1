"""Configuração da aplicação lida de variáveis de ambiente.

Nada de configuração fica fixo no código: o mesmo artefato (imagem Docker)
roda em desenvolvimento, homologação e produção, mudando só o ambiente.
"""
import os


class Config:
    APP_NAME = "devops-fase1"
    APP_ENV = os.getenv("APP_ENV", "development")
    APP_VERSION = os.getenv("APP_VERSION", "dev")
    LOG_LEVEL = os.getenv("LOG_LEVEL", "INFO").upper()
    TESTING = False
