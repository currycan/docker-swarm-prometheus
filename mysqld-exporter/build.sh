#!/bin/sh -e

set -ex

docker build -f mysqld_exporter.Dockerfile . -t currycan/mysqld_exporter:v0.11.0