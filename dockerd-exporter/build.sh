#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f dockerd.Dockerfile . -t currycan/dockerd-exporter:v0.0.1