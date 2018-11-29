FROM golang:1.11.1-alpine3.8 as builder

ENV WORK_DIR $GOPATH/src/github.com/google

WORKDIR $WORK_DIR

RUN set -ex; apk --update --no-cache --no-progress add make git g++ gcc make linux-headers; \
    git clone https://github.com/google/cadvisor.git; \
    cd cadvisor; go get github.com/tools/godep; godep go build; \
    mkdir -p /cadvisor/bin; \
    cp -a cadvisor /cadvisor/bin/

FROM alpine:3.8

LABEL maintainer "Platform/IIBU <zhangzhitao@fmsh.com.cn>"

ENV TZ=Asia/Shanghai
ENV GLIBC_VERSION "2.28-r0"

RUN set -ex; apk --update --no-cache --no-progress add bash tzdata busybox-extras curl ca-certificates device-mapper findutils; \
    apk --no-cache add zfs --repository http://dl-3.alpinelinux.org/alpine/edge/main/; \
    apk --no-cache add thin-provisioning-tools --repository http://dl-3.alpinelinux.org/alpine/edge/main/; \
    wget -q -O /etc/apk/keys/sgerrand.rsa.pub https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub; \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-${GLIBC_VERSION}.apk; \
    wget https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VERSION}/glibc-bin-${GLIBC_VERSION}.apk; \
    apk add glibc-${GLIBC_VERSION}.apk glibc-bin-${GLIBC_VERSION}.apk; \
    /usr/glibc-compat/sbin/ldconfig /lib /usr/glibc-compat/lib; \
    echo 'hosts: files mdns4_minimal [NOTFOUND=return] dns mdns4' >> /etc/nsswitch.conf; \
    ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime; \
    echo ${TZ} > /etc/timezone; \
    rm -rf /var/cache/apk/*

# Grab cadvisor from the staging directory.
COPY --from=builder /cadvisor/bin /bin/
COPY entrypoint/docker-entrypoint.sh /
RUN chmod 770 /*.sh

WORKDIR /cadvisor

VOLUME [ "/cadvisor" ]

EXPOSE 8080

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "-logtostderr" ]
