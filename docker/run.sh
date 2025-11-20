#!/bin/bash
docker compose -f docker/docker-compose.yml up -d --force-recreate --pull always --remove-orphans strato_acme