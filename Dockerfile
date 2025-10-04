FROM alpine:3.20.0 AS builder

# Устанавливаем рабочий каталог
WORKDIR /tmp

# Устанавливаем пакеты с фиксированными версиями
RUN apk add --no-cache \
    build-base=0.5-r3 \
    pcre-dev=8.45-r3 \
    zlib-dev=1.2.13-r1 \
    openssl-dev=3.1.4-r0 && \
    wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz

# Устанавливаем рабочий каталог для сборки nginx
WORKDIR /tmp/nginx-1.24.0

# Собираем nginx
RUN ./configure --prefix=/etc/nginx --user=nginx --group=nginx && \
    make && make install

FROM alpine:3.20.0

# Устанавливаем runtime зависимости
RUN apk add --no-cache \
    pcre=8.45-r3 \
    zlib=1.2.13-r1 \
    openssl=3.1.4-r0 && \
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
