FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai

RUN set -ex; apk --update --no-cache --no-progress add curl bash tzdata busybox-extras; \
    mkdir -p /tmp/unsee; \
    wget --no-check-certificat -P /tmp/unsee https://github.com/cloudflare/unsee/releases/download/v0.9.2/unsee-linux-amd64.tar.gz; \
    tar zxf /tmp/unsee/unsee-linux-amd64.tar.gz -C /tmp/unsee/; \
    mv /tmp/unsee/unsee-linux-amd64 /bin/unsee; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /tmp/unsee /var/cache/apk/*

COPY entrypoint /
RUN chmod 770 /*.sh

WORKDIR /unsee

VOLUME [ "/unsee" ]

EXPOSE 9080

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "unsee" ]
