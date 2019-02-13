### 1、准备    
    基础环境：所有机器安装docker、完成时间校准
---
### 2、开放端口
所有机器运行
```
firewall-cmd --add-port=2376/tcp --permanent
firewall-cmd --add-port=2377/tcp --permanent
firewall-cmd --add-port=7946/tcp --permanent
firewall-cmd --add-port=7946/udp --permanent
firewall-cmd --add-port=4789/udp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --reload 
firewall-cmd --list-ports
```
---
### 3、创建docker swarm集群
a、在prometheus主机上运行
```
docker swarm init
```
控制台会打印加入集群口令，如：
```
docker swarm join --token SWMTKN-1-69tr1fx5grwub5b7zi7qq4tq1crkddpurvf44kn3m57eb0w3xw-1xdagda6avqc512j88j9db70t 192.168.211.117:2377
```
Tips:
    如忘记口令，可通过以下命令查询
```
docker swarm join-token worker
```
b、所有需要监控节点运行加入监控口令，如：
```
docker swarm join --token SWMTKN-1-69tr1fx5grwub5b7zi7qq4tq1crkddpurvf44kn3m57eb0w3xw-1xdagda6avqc512j88j9db70t 192.168.211.117:2377
```
运行完后，可在manager节点查询节点信息：
```
docker node ls
```
c、拉取exporter镜像
比如监控主机需要监控redis,则需要在该主机上拉“harbor.iibu.com/base/redis_exporter:v0.22.1”，具体如下：
    manager节点：docker-compose pull
    worker节点：
        redis主机：docker pull harbor.iibu.com/base/redis_exporter:v0.22.1
        mariadb主机：docker pull harbor.iibu.com/base/mysqld_exporter:v0.11.0
 所有节点都需要用到：cadvisor、node-exporter、dockerd-exporter
 ```
docker pull harbor.iibu.com/base/cadvisor:v0.31.0
docker pull harbor.iibu.com/base/node-exporter:v0.16.0
docker pull harbor.iibu.com/base/dockerd-exporter:v0.0.1
 ```
d、主节点启动服务
在docker-compose.yml所在目录运行
```
mkdir -p /monitor/grafana/data   
mkdir -p /monitor/prometheus/data   
docker stack deploy -c docker-compose.yml monitor
```
服务启动后可查询启动状态：
```
docker service ls
```
如：
```
[root@sup117211 ~]# docker service ls
ID                  NAME                       MODE                REPLICAS            IMAGE                                          PORTS
x5zqc37rgth3        monitor_alertmanager       replicated          0/0                 harbor.iibu.com/base/alertmanager:v0.15.2      
bsy8fkk0cmvg        monitor_caddy              replicated          1/1                 harbor.iibu.com/base/caddy:v0.11.0             *:23000->3000/tcp, *:28080->8080/tcp, *:29080->9080/tcp, *:29090-29091->9090-9091/tcp, *:29093->9093/tcp, *:29100->9100/tcp, *:29323->9323/tcp
43eg2l8h7knb        monitor_cadvisor           global              18/18               harbor.iibu.com/base/cadvisor:v0.31.0          
exe9cf1oyd1r        monitor_dockerd-exporter   global              17/18               harbor.iibu.com/base/dockerd-exporter:v0.0.1   
7fs33k5x5bgo        monitor_grafana            replicated          1/1                 harbor.iibu.com/base/grafana:v5.3.1            
3rcxs9ngy1k2        monitor_node-exporter      global              18/18               harbor.iibu.com/base/node-exporter:v0.16.0     
x88hm8yrbtpu        monitor_prometheus         replicated          1/1                 harbor.iibu.com/base/prometheus:v2.4.3         
9xrx7pnojyab        monitor_pushgateway        replicated          1/1                 harbor.iibu.com/base/pushgateway:v0.6.0        
2doq1da3frdd        monitor_unsee              replicated          1/1                 harbor.iibu.com/base/unsee:v0.9.2 
```
---
### 4、删除集群
```
docker stack rm monitor   
docker container prune   
```
---
### 5、相关命令
a、更新docker-compose文件
```
docker stack deploy -c docker-compose.yml <swarm name>_<app_name>
```
b、更新config文件
```
docker service rm <swarm name>_<app_name>
docker config rm <swarm name>_<config_name>
docker stack deploy -c docker-compose.yml <swarm name>_<app_name>
```
c、集群节点down
```
# manager节点上删除该节点
docker node rm <node_id>
# manager节点查询加入口令
docker swarm join-token worker/manager
# down节点上运行加入节点口令
docker swarm join --token <token> <manager_ip>:2377
```
d、集群节点添加label
```
docker node update --label-add <key>=<value> <node_name>
```
e、如何查看节点label
```
docker node inspect <node_name>
```
f、更新服务镜像版本
```
docker service update --image <image_name:tag> <swarm name>_<app_name>
可以增加优化参数
# 设定容器间更新时间间隔
--update-delay 10s \
# 更新时同时并行更新数量，默认1
--update-parallelism 2 \
# 任务容器更新失败时的模式 continue为继续使用
--update-failure-action continue
```
g、回滚版本
```
docker service update --rollback <swarm name>_<app_name>
可以增加优化参数
--rollback-parallelism 2 \
--rollback-monitor 20s \
--rollback-max-failure-ratio .2 \
```