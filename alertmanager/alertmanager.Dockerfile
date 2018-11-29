FROM golang:1.11.1-alpine3.8 as builder

ENV WORK_DIR $GOPATH/src/github.com/prometheus

WORKDIR $WORK_DIR

RUN set -ex; apk update; apk add --no-cache make curl git; \
    git clone https://github.com/prometheus/alertmanager.git; \
    cd alertmanager; make build; \
    mkdir -p /alertmanager/bin /alertmanager/config; \
    cp -a alertmanager /alertmanager/bin/; \
    cp -a doc/examples/simple.yml /alertmanager/config/simple.yml

FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

COPY --from=builder /alertmanager/bin /bin/
COPY --from=builder /alertmanager/config /etc/alertmanager/

ENV TZ=Asia/Shanghai
RUN set -ex; apk upgrade; apk add curl bash tzdata busybox-extras; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*

COPY config /etc/alertmanager/config
COPY template /etc/alertmanager/template
COPY entrypoint /
RUN chmod 770 /*.sh

WORKDIR /alertmanager

VOLUME [ "/alertmanager" ]

EXPOSE 9093

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "-config.file=/etc/alertmanager/config/alertmanager.yml", \
      "-storage.path=/alertmanager" ]
