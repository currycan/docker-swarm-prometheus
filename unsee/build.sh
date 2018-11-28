#!/bin/sh -e

set -ex

chmod 770 entrypoint/docker-entrypoint.sh
docker build -f unsee.Dockerfile . -t currycan/unsee:v0.9.2