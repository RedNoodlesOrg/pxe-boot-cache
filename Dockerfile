FROM openresty/openresty:alpine-fat

LABEL org.opencontainers.image.title="CoreOS PXE Cache"
LABEL org.opencontainers.image.description="An OpenResty-based caching proxy that always serves the latest Fedora CoreOS PXE artifacts (kernel, initramfs, rootfs) from a local cache."
LABEL org.opencontainers.image.source="https://github.com/RedNoodlesOrg/pxe-boot-cache"
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache ca-certificates \
    && opm get ledgetech/lua-resty-http \
    && update-ca-certificates

RUN addgroup -S nginx && adduser -S -G nginx nginx

RUN mkdir -p /usr/local/openresty/nginx/logs \
    && chown -R nginx:nginx /usr/local/openresty/nginx \
    && mkdir -p /var/cache/nginx/fcos \
    && chown -R nginx:nginx /var/cache/nginx

COPY nginx/nginx.conf /usr/local/openresty/nginx/conf/nginx.conf
COPY nginx/conf.d/coreos-pxe.conf /etc/nginx/conf.d/coreos-pxe.conf

EXPOSE 8080

VOLUME [ "/var/cache/nginx/fcos" ]
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=5 \
  CMD wget -qO- http://127.0.0.1:8080/pxe/version.json >/dev/null || exit 1

STOPSIGNAL SIGQUIT

USER nginx