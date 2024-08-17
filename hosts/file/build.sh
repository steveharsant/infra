#!/usr/bin/env bash

script_path="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

git clone https://github.com/kabe0/deluge-windscribe.git /srv
docker build --no-cache -f /srv/deluge-windscribe/src/Dockerfile -t steveharsant/deluge-windscribe:latest .
docker compose -f "$script_path/docker-compose.yml" up -d
