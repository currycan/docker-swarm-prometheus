#!/bin/sh -e

set -ex

chmod 770 entrypoint/*.sh
docker build -f prometheus.Dockerfile . -t currycan/prometheus:v2.4.3