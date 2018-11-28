#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f cadvisor.Dockerfile . -t currycan/cadvisor:v0.31.0