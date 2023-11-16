FROM alpine:latest as mirror

RUN mkdir -p /out/etc/apk /assets && cp -r /etc/apk/* /out/etc/apk/
RUN apk add --no-cache --initdb -p /out \
    alpine-baselayout \
    busybox \
    curl \
    gpgv \
    jq
RUN rm -rf /out/etc/apk /out/lib/apk /out/var/cache

FROM scratch
ENTRYPOINT []
CMD []
WORKDIR /
COPY --from=mirror /out/ /
COPY --chmod=755 --chown=0:0 ./src/get-fedora-coreos.sh /usr/local/bin/get-fedora-coreos.sh

VOLUME [ "/assets" ]
ENV HOME /assets
WORKDIR $HOME
ENTRYPOINT [ "get-fedora-coreos.sh" ]