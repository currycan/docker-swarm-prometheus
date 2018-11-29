# Build image
FROM golang:1.11.1-alpine as builder

RUN apk add --no-cache git

# clone caddy
RUN git clone https://github.com/mholt/caddy /go/src/github.com/mholt/caddy \
    && cd /go/src/github.com/mholt/caddy \
    && git checkout

# import plugins
COPY build/plugins.go /go/src/github.com/mholt/caddy/caddyhttp/plugins.go

# clone builder
RUN git clone https://github.com/caddyserver/builds /go/src/github.com/caddyserver/builds

# build caddy
RUN cd /go/src/github.com/mholt/caddy/caddy \
    && go get ./... \
    && go run build.go \
    && mv caddy /go/bin

# Dist image
FROM alpine:3.8

# Lable maintainer
LABEL maintainer="zhangzhitao <zhangzhitao@fmsh.com.cn>"

# set timezone
ENV TZ=Asia/Shanghai

# install deps
RUN set -ex; apk upgrade; apk add --no-cache --no-progress bash tzdata busybox-extras curl tini ca-certificates; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*;

# copy caddy binary
COPY --from=builder /go/bin/caddy /bin/caddy

# list plugins
RUN /bin/caddy -plugins

WORKDIR /www

COPY build/index.md /www/index.md
COPY config/Caddyfile /etc/caddy/Caddyfile
COPY entrypoint/docker-entrypoint.sh /
RUN chmod 770 /*.sh

# static files volume
VOLUME ["/www"]

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "caddy", "-agree", "--conf", "/etc/caddy/Caddyfile" ]
