#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f node-exporter.Dockerfile . -t currycan/node-exporter:v0.16.0