#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f caddy.Dockerfile . -t currycan/caddy:v0.11.0