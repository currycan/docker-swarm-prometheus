#!/bin/sh -e

set -exou pipefail

cron() {
      while true ; do
      /update.sh
      sleep 60
    done
}

if [ "${1:0:1}" = '-' ]; then
    mkdir -p /etc/prometheus/prometheus
    mkdir -p /etc/prometheus/cadvisor_exporter
    mkdir -p /etc/prometheus/node_exporter
    mkdir -p /etc/prometheus/dockerd_exporter
    mkdir -p /etc/prometheus/redis_exporter
    mkdir -p /etc/prometheus/mysqld_exporter
    mkdir -p /etc/prometheus/pushgateway
    /update.sh
    if [ -f /prometheus.yml ];then
        \cp -a /prometheus.yml /etc/prometheus/prometheus.yml
    else
        cat /etc/prometheus/prometheus.yml > /tmp/prometheus.yml
        cat /etc/prometheus/weave-cortex.yml | \
        sed "s@#password: <token>#@password: '$WEAVE_TOKEN'@g" > /tmp/weave-cortex.yml
        #JOBS=mongo-exporter:9111 redis-exporter:9112

        if [ ${JOBS+x} ]; then
            for job in $JOBS;do
                echo "adding job $job"
                SERVICE=$(echo "$job" | cut -d":" -f1)
                PORT=$(echo "$job" | cut -d":" -f2)
                cat >>/tmp/prometheus.yml <<EOF

  - job_name: '${SERVICE}'
    dns_sd_configs:
    - names:
      - 'tasks.${SERVICE}'
      type: 'A'
      port: ${PORT}
EOF
                cat >>/tmp/weave-cortex.yml <<EOF

  - job_name: '${SERVICE}'
    dns_sd_configs:
    - names:
      - 'tasks.${SERVICE}'
      type: 'A'
      port: ${PORT}
EOF
            done
        fi
        mv /tmp/prometheus.yml /etc/prometheus/prometheus.yml
        mv /tmp/weave-cortex.yml /etc/prometheus/weave-cortex.yml
    fi
    cron &
    set -- /bin/prometheus "$@"
fi
exec "$@"

