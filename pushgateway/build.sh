#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f pushgateway.Dockerfile . -t currycan/pushgateway:v0.6.0