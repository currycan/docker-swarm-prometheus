#!/bin/sh -e

set -exou pipefail

if [ "${1#-}" = "caddy" ]; then
    set -- "/sbin/tini" "$@"
fi
exec "$@"
