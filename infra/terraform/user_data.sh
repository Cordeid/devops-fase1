#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io curl
systemctl enable --now docker

# Roda a mesma imagem que passou pelos testes e pela homologação no pipeline
docker pull ${app_image}
docker run -d --name devops-app --restart unless-stopped \
  -p 5000:5000 -e APP_ENV=production \
  --read-only --tmpfs /tmp --security-opt no-new-privileges \
  ${app_image}
