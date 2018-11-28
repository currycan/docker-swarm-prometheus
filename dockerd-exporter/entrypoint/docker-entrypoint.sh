#!/bin/bash

set -exou pipefail

file_env() {
    local var="$1"
    local fileVar="${var}_FILE"
    local def="${2:-}"
    if [ "${!var:-}" ] && [ "${!fileVar:-}" ]; then
        echo >&2 "error: both $var and $fileVar are set (but are exclusive)"
        exit 1
    fi
    local val="$def"
    if [ "${!var:-}" ]; then
        val="${!var}"
    elif [ "${!fileVar:-}" ]; then
        val="$(< "${!fileVar}")"
    fi
    export "$var"="$val"
    unset "$fileVar"
}

sed_conf() {
    local var="$1"
    local file="$2"
    sed -i -e "s!\${$var}!`eval echo '$'"$var"`!g" ${file}
    sed -i -e "s!\$$var!`eval echo '$'"$var"`!g" ${file}
}

if [ "${1#-}" = "dockerd-exporter" ]; then
    IP_NET=`ip route|awk '/default/ { print $5 }'`
    DOCKERD_IP=`route -n | grep $IP_NET | grep UG | awk '{print $2}'`
    file_env DOCKERD_IP
    sed_conf DOCKERD_IP /etc/nginx/conf.d/dockerd.conf
    set -- "nginx" "-g" "daemon off;"
fi
exec "$@"
