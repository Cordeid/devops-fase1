#!/bin/bash
set -e
apt-get update -y
apt-get install -y docker.io git
systemctl enable --now docker

git clone ${repo_url} /opt/app
cd /opt/app
docker build -t devops-fase1 .
docker run -d --restart always -p 5000:5000 --name app devops-fase1
