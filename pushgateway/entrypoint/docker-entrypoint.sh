#!/bin/sh -e

set -exou pipefail

if [ "${1#-}" = "pushgateway" ]; then
    set -- /bin/pushgateway
fi
exec "$@"
