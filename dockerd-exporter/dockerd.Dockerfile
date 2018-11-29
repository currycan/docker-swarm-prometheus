FROM nginx:1.14-alpine

LABEL maintainer="zhangzhitao <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai
RUN set -ex; apk upgrade; apk add --no-cache --no-progress bash tzdata busybox-extras curl ca-certificates; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*;

COPY config/dockerd.conf /etc/nginx/conf.d/dockerd.conf
COPY entrypoint/docker-entrypoint.sh /
RUN chmod 770 /*.sh

EXPOSE 9323

STOPSIGNAL SIGTERM

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "dockerd-exporter" ]
