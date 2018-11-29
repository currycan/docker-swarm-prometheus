FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai
RUN set -ex; apk upgrade; apk add curl bash tzdata ca-certificates; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*; \
    curl -o /bin/redis_exporter https://raw.githubusercontent.com/docker-swarm-prometheus/docker_image/master/redis-exporter/redis_exporter; \
    chmod 770 /bin/redis_exporter

WORKDIR /redis_exporter

VOLUME [ "/redis_exporter" ]

EXPOSE 9121

CMD /bin/redis_exporter ${OPTS}
