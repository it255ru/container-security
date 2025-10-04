FROM alpine:3.20.0 AS nginx-builder

# Устанавливаем рабочий каталог
WORKDIR /tmp

# Скачиваем и компилируем nginx без ненужных модулей
RUN apk add --no-cache \
        build-base=0.5-r3 \
        pcre-dev=8.45-r3 \
        zlib-dev=1.2.13-r1 \
        openssl-dev=3.1.4-r0 && \
    wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz && \
    cd nginx-1.24.0 && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --without-http_autoindex_module \
        --without-http_ssi_module \
        --without-http_scgi_module \
        --without-http_uwsgi_module \
        --without-http_fastcgi_module && \
    make && make install

FROM alpine:3.20.0

RUN addgroup -S nginx && adduser -S -D -H -G nginx nginx

COPY --from=nginx-builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-builder /etc/nginx /etc/nginx

RUN mkdir -p /var/log/nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx

COPY nginx-minimal.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx html /var/www/html

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
