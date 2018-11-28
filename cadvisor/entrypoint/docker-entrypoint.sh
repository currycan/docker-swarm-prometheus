#!/bin/sh -e

set -exou pipefail

if [ "${1:0:1}" = '-' ]; then
    set -- /bin/cadvisor "$@"
fi
exec "$@"
