FROM golang:1.11.1-alpine3.8 as builder

ENV WORK_DIR $GOPATH/src/github.com/prometheus

WORKDIR $WORK_DIR

RUN set -ex; apk update; apk add --no-cache curl make git; \
    git clone https://github.com/prometheus/prometheus.git; \
    cd prometheus; make build; \
    mkdir -p /prometheus/bin /prometheus/config; \
    cp -a prometheus /prometheus/bin/prometheus; \
    cp -a promtool /prometheus/bin/promtool; \
    cp -a documentation/examples/prometheus.yml /prometheus/config/prometheus.yml; \
    cp -a console_libraries/ /prometheus/; \
    cp -a consoles/ /prometheus/

FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

COPY --from=builder /prometheus/bin /bin/
COPY --from=builder /prometheus/config/prometheus.yml /etc/prometheus/prometheus.yml
COPY --from=builder /prometheus/console_libraries/ /usr/share/prometheus/console_libraries/
COPY --from=builder /prometheus/consoles/ /usr/share/prometheus/consoles/

ENV TZ=Asia/Shanghai
RUN set -ex; apk upgrade; apk add curl bash tzdata jq; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*; \
    ln -s /usr/share/prometheus/console_libraries /usr/share/prometheus/consoles/ /etc/prometheus/

COPY config /etc/prometheus/
COPY entrypoint /
RUN chmod 770 /*.sh

ENV WEAVE_TOKEN=none

WORKDIR /prometheus

VOLUME [ "/prometheus" ]

EXPOSE 9090

ENTRYPOINT  [ "/docker-entrypoint.sh" ]

CMD [ "--config.file=/etc/prometheus/prometheus.yml", \
      "--storage.tsdb.path=/prometheus", \
      "--web.console.libraries=/usr/share/prometheus/console_libraries", \
      "--web.console.templates=/usr/share/prometheus/consoles" ]

