FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai
ENV GRAFANA_VERSION=5.3.1

RUN set -ex; apk upgrade; apk add --no-cache --no-progress bash tzdata busybox-extras curl ca-certificates libc6-compat su-exec; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    mkdir -p /tmp/grafana; curl http://s3-us-west-2.amazonaws.com/grafana-releases/release/grafana-${GRAFANA_VERSION}.linux-amd64.tar.gz \
    | tar xfz - --strip-components=1 -C /tmp/grafana; \
    install -m 755 /tmp/grafana/bin/grafana-server /usr/sbin/; \
    install -m 755 /tmp/grafana/bin/grafana-cli /usr/sbin/; \
    mkdir -p /grafana/home/.aws /grafana/data /grafana/logs /grafana/plugins; \
    cp -a /tmp/grafana/conf /grafana/home/; \
    cp -a /tmp/grafana/public /grafana/home/; \
    cp -a /tmp/grafana/VERSION /grafana/home/; \
    # grafana-cli plugins update-all; \
    # addgroup -S grafana; \
    # adduser -S -G grafana grafana; \
    # chown -R grafana:grafana /grafana; \
    rm -rf /tmp/grafana /var/cache/apk/*;

ENV GF_PATHS_HOME=/grafana/home \
    GF_PATHS_LOGS=/grafana/logs \
    GF_PATHS_DATA=/grafana/data \
    GF_PATHS_PLUGINS=/grafana/plugins \
    GF_PATHS_CONFIG=/grafana/config/grafana.ini \
    GF_PATHS_PROVISIONING=/grafana/config/provisioning \
    DATASOURCES_PATH=/grafana/datasources \
    DASHBOARDS_PATH=/grafana/dashboards \
    UPGRADEALL=false \
    GF_SECURITY_ADMIN_PASSWORD=admin \
    GF_SECURITY_ADMIN_USER=admin

COPY config /grafana/config/
COPY datasources /grafana/datasources/
COPY dashboards /grafana/dashboards/
COPY entrypoint /
RUN chmod 770 /*.sh

EXPOSE 3000

WORKDIR /grafana

VOLUME ["/grafana"]

ENTRYPOINT  [ "/docker-entrypoint.sh" ]

CMD [ "grafana" ]
