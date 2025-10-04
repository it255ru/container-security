FROM alpine:3.20.0 AS nginx-builder

WORKDIR /tmp

# Устанавливаем зависимости
RUN apk add --no-cache build-base pcre-dev zlib-dev openssl-dev

# Скачиваем и распаковываем nginx
RUN wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz
RUN tar -xzf nginx.tar.gz

WORKDIR /tmp/nginx-1.24.0

# Создаем скрипт конфигурации для избежания длинной команды
RUN cat > configure.sh << 'EOF'
#!/bin/sh
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
    --without-http_fastcgi_module
EOF

RUN chmod +x configure.sh && ./configure.sh
RUN make && make install

# Создаем временные директории
RUN mkdir -p /var/cache/nginx/client_temp \
    /var/cache/nginx/proxy_temp \
    /var/cache/nginx/fastcgi_temp \
    /var/cache/nginx/uwsgi_temp \
    /var/cache/nginx/scgi_temp

FROM alpine:3.20.0

# Runtime зависимости
RUN apk add --no-cache pcre zlib openssl

# Создаем пользователя и группы
RUN addgroup -S nginx && adduser -S -D -H -G nginx nginx

# Копируем собранный nginx
COPY --from=nginx-builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-builder /etc/nginx /etc/nginx
COPY --from=nginx-builder /var/cache/nginx /var/cache/nginx

# Создаем структуру директорий
RUN mkdir -p /var/log/nginx /var/www/html /var/run/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/www/html /var/run/nginx

# Копируем конфигурацию
COPY nginx-minimal.conf /etc/nginx/nginx.conf

# Копируем статические файлы
COPY --chown=nginx:nginx html /var/www/html

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
