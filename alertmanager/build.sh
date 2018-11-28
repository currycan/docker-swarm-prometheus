#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f alertmanager.Dockerfile . -t currycan/alertmanager:v0.15.2