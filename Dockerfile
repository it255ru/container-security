FROM alpine:3.20.0 AS builder

WORKDIR /tmp

RUN apk add --no-cache build-base pcre-dev zlib-dev openssl-dev && \
    wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz && \
    cd nginx-1.24.0 && \
    ./configure --prefix=/etc/nginx --user=nginx --group=nginx && \
    make && make install

FROM alpine:3.20.0

RUN apk add --no-cache pcre zlib openssl && \
    addgroup -S nginx && adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html && \
    chown -R nginx:nginx /var/log/nginx /var/www/html

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY nginx-minimal.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx html /var/www/html

USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
