#!/bin/sh -e

set -exou pipefail

if [ "${1:0:1}" = '-' ]; then
    echo "Wait 5s for promethues up.. "
    sleep 5
    cat /etc/alertmanager/config/alertmanager.yml | \
        sed "s@<CORP_ID>@$CORP_ID@g" | \
        sed "s@<PARTY>@$PARTY@g" | \
        sed "s@<AGENT_ID>@$AGENT_ID@g" | \
        sed "s@<AUTH_CODE>@$AUTH_CODE@g" | \

        sed "s!<EMAIL_USER>!$EMAIL_USER!g" | \

        sed "s@<SLACK_USER>@$SLACK_USER@g" | \
        sed "s@<SLACK_CHANNEL>@$SLACK_CHANNEL@g" | \
        sed "s@<SLACK_URL>@$SLACK_URL@g" | \

        sed "s@<REPEAT>@$REPEAT@g" | \
        sed "s@<RECEIVER>@$RECEIVER@g" > /tmp/alertmanager.yml
    mv /tmp/alertmanager.yml /etc/alertmanager/config/alertmanager.yml

    set -- /bin/alertmanager "$@"
fi

exec "$@"