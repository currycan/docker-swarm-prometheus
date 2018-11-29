FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai

RUN set -ex; apk --update --no-cache --no-progress add curl bash tzdata busybox-extras; \
    mkdir -p /tmp/pushgateway; \
    wget --no-check-certificat -P /tmp/pushgateway https://github.com/prometheus/pushgateway/releases/download/v0.6.0/pushgateway-0.6.0.linux-amd64.tar.gz; \
    tar zxf /tmp/pushgateway/pushgateway-0.6.0.linux-amd64.tar.gz -C /tmp/pushgateway/; \
    mv /tmp/pushgateway/pushgateway-0.6.0.linux-amd64/pushgateway /bin/; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /tmp/pushgateway /var/cache/apk/*

COPY entrypoint /
RUN chmod 770 /*.sh

WORKDIR /pushgateway

VOLUME [ "/pushgateway" ]

EXPOSE 9091

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "pushgateway" ]
