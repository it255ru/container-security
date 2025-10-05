FROM alpine:3.20.0 AS builder

WORKDIR /tmp

# Устанавливаем пакеты без фиксированных версий (используем последние доступные)
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev && \
    wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz

WORKDIR /tmp/nginx-1.24.0

# Собираем nginx
RUN ./configure --prefix=/etc/nginx --user=nginx --group=nginx && \
    make && make install

FROM alpine:3.20.0

# Устанавливаем runtime зависимости без фиксированных версий
RUN apk add --no-cache \
    pcre \
    zlib \
    openssl && \
    addgroup -S nginx && \
    adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html && \
    chown -R nginx:nginx /var/log/nginx /var/www/html

# Копируем собранный nginx
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

# Копируем конфигурацию и статические файлы
COPY nginx-minimal.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx html /var/www/html

USER nginx
EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
