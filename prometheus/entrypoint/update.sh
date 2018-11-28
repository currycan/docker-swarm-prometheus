#!/bin/bash -e

set -e

: "${exporters=${exporters:-prometheus node_exporter cadvisor_exporter dockerd_exporter redis_exporter mysqld_exporter pushgateway}}"
: "${stack=${stack:-monitor}}"

for exporterKey in ${exporters[@]};do
    cmd="curl -s -g -H \"Content-Type: application/json\" --unix-socket /var/run/docker.sock \"http:/v1.24/tasks?filters={"\\\"desired-state"\\\":["\\\"running"\\\"],"\\\"service"\\\":["\\\"${stack}_${exporterKey}"\\\"]}\" | jq '[.[] | {targets: .NetworksAttachments[0].Addresses[0], labels: {node_id: .NodeID}}]' | sed 's@\/24@:0000@g'"
    # echo $cmd
    config_file=$(eval ${cmd})
    echo "[" > tmp.json
    for row in $(echo $config_file | jq -r '.[] | @base64'); do
        _jq() {
         echo ${row} | base64 -d | jq -r ${1}
        }
        TARGET=[\"$(_jq '.targets')\"]
        cmd_label="curl -s --unix-socket /var/run/docker.sock http:/v1.31/nodes/$(_jq '.labels.node_id') | jq '.|{\"job\": \"${exporterKey}\", \"node_id\": .ID, \"hostname\": .Description.Hostname, \"host_ip\": .Status.Addr}'"
        # echo $cmd_label
        LABEL=$(eval ${cmd_label})
        echo \{\"targets\":$TARGET,\"labels\":$LABEL\} >> tmp.json
        echo "," >> tmp.json
    done
    echo  "]" >> tmp.json
    tac tmp.json | sed '2d' | tac | jq . > /etc/prometheus/${exporterKey}/scrape.json
done

if [ -f /etc/prometheus/prometheus/scrape.json ];then
    sed -i 's@0000@9090@g' /etc/prometheus/prometheus/scrape.json
fi
if [ -f /etc/prometheus/node_exporter/scrape.json ];then
    sed -i 's@0000@9100@g' /etc/prometheus/node_exporter/scrape.json
fi
if [ -f /etc/prometheus/cadvisor_exporter/scrape.json ];then
    sed -i 's@0000@8080@g' /etc/prometheus/cadvisor_exporter/scrape.json
fi
if [ -f /etc/prometheus/dockerd_exporter/scrape.json ];then
    sed -i 's@0000@9323@g' /etc/prometheus/dockerd_exporter/scrape.json
fi
if [ -f /etc/prometheus/redis_exporter/scrape.json ];then
    sed -i 's@0000@9121@g' /etc/prometheus/redis_exporter/scrape.json
fi
if [ -f /etc/prometheus/mysqld_exporter/scrape.json ];then
    sed -i 's@0000@9104@g' /etc/prometheus/mysqld_exporter/scrape.json
fi
if [ -f /etc/prometheus/pushgateway/scrape.json ];then
    sed -i 's@0000@9091@g' /etc/prometheus/pushgateway/scrape.json
fi



