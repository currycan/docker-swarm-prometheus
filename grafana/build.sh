#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f grafana.Dockerfile . -t currycan/grafana:v5.3.1