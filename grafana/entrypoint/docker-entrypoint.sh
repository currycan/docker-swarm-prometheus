#!/usr/bin/env bash

set -eou pipefail
shopt -s nullglob

Green_font_prefix="\033[32m" && Red_font_prefix="\033[31m" && Yellow_font_prefix="\033[33m" && \
Green_background_prefix="\033[42;37m" && Red_background_prefix="\033[41;37m" && Yellow_background_prefix="\033[43;37m" && \
Font_color_suffix="\033[0m"
Info="${Green_font_prefix}Info${Font_color_suffix}" && \
Error="${Red_font_prefix}Error${Font_color_suffix}" && \
Warning="${Yellow_font_prefix}Warning${Font_color_suffix}"

logInfo(){
    # format 2018-10-27 03:43:28
    # TIME=`date "+%Y-%m-%d %H:%M:%S"`
    # format [10-27|03:50:14]
    TIME=`date "+[%m-%d|%H:%M:%S]"`
    echo -e "${Info}${TIME} ${Green_font_prefix}$@${Font_color_suffix}"
}

logError(){
    # format 2018-10-27 03:43:28
    # TIME=`date "+%Y-%m-%d %H:%M:%S"`
    # format [10-27|03:50:14]
    TIME=`date "+[%m-%d|%H:%M:%S]"`
    echo -e "${Error}${TIME} ${Green_font_prefix}$@${Font_color_suffix}"
}

logWarning(){
    # format 2018-10-27 03:43:28
    # TIME=`date "+%Y-%m-%d %H:%M:%S"`
    # format [10-27|03:50:14]
    TIME=`date "+[%m-%d|%H:%M:%S]"`
    echo -e "${Warning}${TIME} ${Green_font_prefix}$@${Font_color_suffix}"
}

start() {
    PERMISSIONS_OK=0
    : "${HOST_IP=${HOST_IP:-localhost}}"
    : "${GRAFANA_URL=${GRAFANA_URL:-http://$GF_SECURITY_ADMIN_USER:$GF_SECURITY_ADMIN_PASSWORD@$HOST_IP:3000}}"
    : "${UPGRADEALL=${UPGRADEALL:-false}}"
    : "${GF_SMTP_ENABLED=${GF_SMTP_ENABLED:-true}}"
    : "${GF_SMTP_HOST=${GF_SMTP_HOST:-smtp.163.com:25}}"
    : "${GF_SMTP_USER=${GF_SMTP_USER:-fmsh_iibu_plat@163.com}}"
    : "${GF_SMTP_PASSWORD=${GF_SMTP_PASSWORD:-pass123word456}}"
    : "${GF_SMTP_FROM_ADDRESS=${GF_SMTP_FROM_ADDRESS:-fmsh_iibu_plat@163.com}}"
    : "${GF_USERS_ALLOW_SIGN_UP=${GF_USERS_ALLOW_SIGN_UP:-false}}"
    : "${GF_SERVER_ROOT_URL=${GF_SERVER_ROOT_URL:-localhost}}"
    # : "${GF_INSTALL_PLUGINS=${GF_INSTALL_PLUGINS:-grafana-clock-panel,grafana-simple-json-datasource}}"

    if [ ! -r "$GF_PATHS_CONFIG" ]; then
        logError "GF_PATHS_CONFIG='$GF_PATHS_CONFIG' is not readable."
        PERMISSIONS_OK=1
    fi

    if [ ! -w "$GF_PATHS_DATA" ]; then
        logError "GF_PATHS_DATA='$GF_PATHS_DATA' is not writable."
        PERMISSIONS_OK=1
    fi

    if [ ! -r "$GF_PATHS_HOME" ]; then
        logError "GF_PATHS_HOME='$GF_PATHS_HOME' is not readable."
        PERMISSIONS_OK=1
    fi

    if [ $PERMISSIONS_OK -eq 1 ]; then
        logWarning "You may have issues with file permissions, more information here: http://docs.grafana.org/installation/docker/#migration-from-a-previous-version-of-the-docker-container-to-5-1-or-later"
    fi

    if [ ! -d "$GF_PATHS_PLUGINS" ]; then
        mkdir -p "$GF_PATHS_PLUGINS"
    fi

    if [ ! -z ${GF_AWS_PROFILES+x} ]; then
        > "$GF_PATHS_HOME/.aws/credentials"

        for profile in ${GF_AWS_PROFILES}; do
            access_key_varname="GF_AWS_${profile}_ACCESS_KEY_ID"
            secret_key_varname="GF_AWS_${profile}_SECRET_ACCESS_KEY"
            region_varname="GF_AWS_${profile}_REGION"

            if [ ! -z "${!access_key_varname}" -a ! -z "${!secret_key_varname}" ]; then
                echo "[${profile}]" >> "$GF_PATHS_HOME/.aws/credentials"
                echo "aws_access_key_id = ${!access_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                echo "aws_secret_access_key = ${!secret_key_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                if [ ! -z "${!region_varname}" ]; then
                    echo "region = ${!region_varname}" >> "$GF_PATHS_HOME/.aws/credentials"
                fi
            fi
        done

        chmod 600 "$GF_PATHS_HOME/.aws/credentials"
    fi

    if [ "$UPGRADEALL" = true ] ; then
        grafana-cli --pluginsDir "${GF_PATHS_PLUGINS}" plugins upgrade-all || true
    fi

    # Convert all environment variables with names ending in __FILE into the content of
    # the file that they point at and use the name without the trailing __FILE.
    # This can be used to carry in Docker secrets.
    for VAR_NAME in $(env | grep '^GF_[^=]\+__FILE=.\+' | sed -r "s/([^=]*)__FILE=.*/\1/g"); do
        VAR_NAME_FILE="$VAR_NAME"__FILE
        if [ "${!VAR_NAME}" ]; then
            logError >&2 "ERROR: Both $VAR_NAME and $VAR_NAME_FILE are set (but are exclusive)"
            exit 1
        fi
        logInfo "Getting secret $VAR_NAME from ${!VAR_NAME_FILE}"
        export "$VAR_NAME"="$(< "${!VAR_NAME_FILE}")"
        unset "$VAR_NAME_FILE"
    done

    export HOME="$GF_PATHS_HOME"

    if [ ! -z "${GF_INSTALL_PLUGINS+x}" ]; then
        OLDIFS=$IFS
        IFS=','
        for plugin in ${GF_INSTALL_PLUGINS}; do
            IFS=$OLDIFS
            if [[ $plugin =~ .*\;.* ]]; then
                pluginUrl=$(echo "$plugin" | cut -d';' -f 1)
                pluginWithoutUrl=$(echo "$plugin" | cut -d';' -f 2)
                grafana-cli --pluginUrl "${pluginUrl}" --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${pluginWithoutUrl}
            else
                grafana-cli --pluginsDir "${GF_PATHS_PLUGINS}" plugins install ${plugin}
            fi
        done
    fi
}

# Generic function to call the Vault API
grafana_api() {
    local verb=$1
    local url=$2
    local params=$3
    local bodyfile=$4
    local response
    local cmd

    cmd="curl -L -s --fail -H \"Accept: application/json\" -H \"Content-Type: application/json\" -X ${verb} -k ${GRAFANA_URL}${url}"
    [[ -n "${params}" ]] && cmd="${cmd} -d \"${params}\""
    [[ -n "${bodyfile}" ]] && cmd="${cmd} --data @${bodyfile}"
    logInfo "${Green_font_prefix}Running ${cmd}${Font_color_suffix}"
    eval ${cmd} && echo "" || return 1
    return 0
}

wait_for_api() {
    local verb=GET
    local url=/api/user/preferences
    cmd="curl -L -s --fail -H \"Accept: application/json\" -H \"Content-Type: application/json\" -X ${verb} -k ${GRAFANA_URL}${url}"
    sleep 5
    logInfo "${Green_font_prefix}Running ${cmd}${Font_color_suffix}"
    eval ${cmd} && echo "" && logInfo "${Green_font_prefix}Server is already up!${Font_color_suffix}" && return 0 || sleep 5 && \
    logWarning "${Yellow_font_prefix}Server is Starting... ${Font_color_suffix}" && wait_for_api
}

install_datasources() {
    local datasource
    for datasource in ${DATASOURCES_PATH}/*.json
    do
    if [[ -f "${datasource}" ]]; then
        logInfo ">>>>>>>>>>Start to install datasource ${datasource}"
        if grafana_api POST /api/datasources "" "${datasource}"; then
            logInfo "${Green_font_prefix}>>>>>>>>>>>>>>>>installed success!<<<<<<<<<<<<<<<<${Font_color_suffix}"
        else
            logError "${Red_font_prefix}>>>>>>>>>>>>>>>>install failed!!<<<<<<<<<<<<<<<<${Font_color_suffix}"
        fi
    fi
    done
}

install_dashboards() {
    local dashboard
    for dashboard in ${DASHBOARDS_PATH}/*.json
    do
    if [[ -f "${dashboard}" ]]; then
        logInfo ">>>>>>>>>>Start to install dashboard ${dashboard}"
        echo "{\"dashboard\": `cat $dashboard`}" > "${dashboard}.wrapped"

        if grafana_api POST /api/dashboards/db "" "${dashboard}.wrapped"; then
            logInfo "${Green_font_prefix}>>>>>>>>>>>>>>>>installed success!<<<<<<<<<<<<<<<<${Font_color_suffix}"
        else
            logError "${Red_font_prefix}>>>>>>>>>>>>>>>>install failed!!<<<<<<<<<<<<<<<<${Font_color_suffix}"
        fi
      rm "${dashboard}.wrapped"
    fi
    done
}

configure_grafana() {
    wait_for_api
    install_datasources
    install_dashboards
}

if [ "${1#-}" = "grafana" ]; then
    start
    configure_grafana &
    logInfo ">>>>>>>> Starting grafana server..."
    exec grafana-server                                       \
    --homepath="$GF_PATHS_HOME"                               \
    --config="$GF_PATHS_CONFIG"                               \
    cfg:default.log.mode="console"                            \
    cfg:default.paths.data="$GF_PATHS_DATA"                   \
    cfg:default.paths.logs="$GF_PATHS_LOGS"                   \
    cfg:default.paths.plugins="$GF_PATHS_PLUGINS"             \
    cfg:default.smtp.enabled="$GF_SMTP_ENABLED"               \
    cfg:default.smtp.host="$GF_SMTP_HOST"                     \
    cfg:default.smtp.user="$GF_SMTP_USER"                     \
    cfg:default.smtp.password="$GF_SMTP_PASSWORD"             \
    cfg:default.smtp.from_address="$GF_SMTP_FROM_ADDRESS"     \
    cfg:default.paths.provisioning="$GF_PATHS_PROVISIONING"
fi
exec "$@"

