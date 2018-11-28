#!/bin/sh -e

set -ex

docker build -f redis_exporter.Dockerfile . -t currycan/redis_exporter:v0.22.1