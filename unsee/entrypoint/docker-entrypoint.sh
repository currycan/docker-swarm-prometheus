#!/bin/sh -e

set -exou pipefail

if [ "${1#-}" = "unsee" ]; then
    set -- /bin/unsee
fi
exec "$@"
