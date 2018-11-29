FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai
RUN set -ex; apk upgrade; apk add curl bash tzdata ca-certificates; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*; \
    curl -o /bin/mysqld_exporter https://raw.githubusercontent.com/currycan/docker-swarm-prometheus/master/mysqld_exporter/mysqld_exporter; \
    chmod 770 /bin/mysqld_exporter

WORKDIR /mysqld_exporter

VOLUME [ "/mysqld_exporter" ]

EXPOSE 9104

CMD /bin/mysqld_exporter ${OPTS}
