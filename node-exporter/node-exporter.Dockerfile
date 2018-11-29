FROM golang:1.11.1-alpine3.8 as builder

ENV WORK_DIR $GOPATH/src/github.com/prometheus/

WORKDIR $WORK_DIR

RUN set -ex; apk update; apk add --no-cache make git; \
    git clone https://github.com/prometheus/node_exporter.git; \
    cd node_exporter; make build; \
    mkdir -p /node_exporter/bin; \
    cp -a node_exporter /node_exporter/bin/

FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai

# Here we install GNU libc (aka glibc) and set C.UTF-8 locale as default.
RUN set -ex; apk upgrade; apk add curl bash tzdata busybox-extras; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    ALPINE_GLIBC_BASE_URL="https://github.com/sgerrand/alpine-pkg-glibc/releases/download"; \
    ALPINE_GLIBC_PACKAGE_VERSION="2.28-r0"; \
    ALPINE_GLIBC_BASE_PACKAGE_FILENAME="glibc-$ALPINE_GLIBC_PACKAGE_VERSION.apk"; \
    ALPINE_GLIBC_BIN_PACKAGE_FILENAME="glibc-bin-$ALPINE_GLIBC_PACKAGE_VERSION.apk"; \
    ALPINE_GLIBC_I18N_PACKAGE_FILENAME="glibc-i18n-$ALPINE_GLIBC_PACKAGE_VERSION.apk"; \
    apk add --no-cache --virtual=.build-dependencies wget ca-certificates; \
    echo \
        "-----BEGIN PUBLIC KEY-----\
        MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEApZ2u1KJKUu/fW4A25y9m\
        y70AGEa/J3Wi5ibNVGNn1gT1r0VfgeWd0pUybS4UmcHdiNzxJPgoWQhV2SSW1JYu\
        tOqKZF5QSN6X937PTUpNBjUvLtTQ1ve1fp39uf/lEXPpFpOPL88LKnDBgbh7wkCp\
        m2KzLVGChf83MS0ShL6G9EQIAUxLm99VpgRjwqTQ/KfzGtpke1wqws4au0Ab4qPY\
        KXvMLSPLUp7cfulWvhmZSegr5AdhNw5KNizPqCJT8ZrGvgHypXyiFvvAH5YRtSsc\
        Zvo9GI2e2MaZyo9/lvb+LbLEJZKEQckqRj4P26gmASrZEPStwc+yqy1ShHLA0j6m\
        1QIDAQAB\
        -----END PUBLIC KEY-----" | sed 's/   */\n/g' > "/etc/apk/keys/sgerrand.rsa.pub"; \
    wget \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BASE_URL/$ALPINE_GLIBC_PACKAGE_VERSION/$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"; \
    apk add --no-cache \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"; \
    \
    rm "/etc/apk/keys/sgerrand.rsa.pub"; \
    /usr/glibc-compat/bin/localedef --force --inputfile POSIX --charmap UTF-8 "$LANG" || true; \
    echo "export LANG=$LANG" > /etc/profile.d/locale.sh; \
    \
    apk del glibc-i18n; \
    \
    rm "/root/.wget-hsts"; \
    apk del .build-dependencies; \
    rm \
        "$ALPINE_GLIBC_BASE_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_BIN_PACKAGE_FILENAME" \
        "$ALPINE_GLIBC_I18N_PACKAGE_FILENAME"; \
    rm -rf /var/cache/apk/*

COPY --from=builder /node_exporter/bin /bin/
COPY entrypoint /
RUN chmod 770 /*.sh

WORKDIR /node_exporter

VOLUME [ "/node_exporter" ]

EXPOSE 9100

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "--path.sysfs=/host/sys", \
      "--path.procfs=/host/proc", \
      "--collector.textfile.directory=/etc/node-exporter/", \
      "--collector.filesystem.ignored-mount-points=^/(sys|proc|dev|host|etc)($$|/)", \
      # no collectors are explicitely enabled here, because the defaults are just fine,
      # see https://github.com/prometheus/node_exporter
      # disable ipvs collector because it barfs the node-exporter logs full with errors on my centos 7 vm's
      "--no-collector.ipvs" ]
