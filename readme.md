### 准备
docker stack rm mm
sleep 5
rm -rf /monitor
mkdir -p /monitor/grafana/data   
mkdir -p /monitor/prometheus/data   
docker ps -a 
docker container prune  

### 创建集群
docker swarm init --advertise-addr <HOST_IP>   
docker swarm init --advertise-addr 192.168.43.92   
### 启动集群服务
docker container prune
y
docker stack deploy -c docker-compose.yml mm
docker service ls

### 删除集群
docker stack rm <NAME>   
docker container prune   

ip -o addr show docker_gwbridge

重新生成docker_gwbridge
ip link set docker_gwbridge down
ip link del dev docker_gwbridge
systemctl restart docker

docker run -d -p 80:80 -l hostname=pure-1804 -l host_ip=192.168.1.12 nginx:alpine

 container_last_seen{id=~"/docker/.+"} * on(instance) group_left(node_id) swarm_node_info
 container_last_seen{id=~"/docker/.+", container_label_com_docker_swarm_node_id=""}

engine_daemon_health_checks_failed_total * on(instance) group_left(node_id) swarm_node_info

node_filesystem_free_bytes * on(instance) group_left(node)
container_last_seen * on(namespace, pod_name) group_left(node) 
* on(instance) group_left(node_name) node_meta{node_id=~"$node_id"})
curl -L -s --fail -H "Accept: application/json" -H "Content-Type: application/json" -X GET -k http://admin:admin@localhost:3000/api/user/preferences