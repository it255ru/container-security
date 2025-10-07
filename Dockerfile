# Используем Alpine 3.21.0 который содержит OpenSSL 3.3.5
FROM alpine:3.21.0 AS builder

WORKDIR /tmp

# Устанавливаем пакеты без явных версий - используем те что есть в репозитории
RUN apk update && apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar

RUN wget --no-verbose -O nginx.tar.gz "https://nginx.org/download/nginx-1.24.0.tar.gz" && \
    tar -xzf nginx.tar.gz

WORKDIR /tmp/nginx-1.24.0

RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module && \
    make -j"$(nproc)" && \
    make install

# Runtime этап
FROM alpine:3.21.0

# Устанавливаем только необходимые пакеты - Alpine 3.21.0 уже содержит исправленные версии
RUN apk add --no-cache \
    pcre \
    zlib \
    openssl && \
    addgroup -S nginx && \
    adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html /var/run

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

# Copy your configuration file
COPY nginx-minimal.conf /etc/nginx/nginx.conf

# Copy custom HTML content
COPY --chown=nginx:nginx html /var/www/html/

# Set permissions
RUN chown -R nginx:nginx /etc/nginx /var/log/nginx /var/run

USER nginx

EXPOSE 8080
CMD ["sh", "-c", "nginx -t && nginx -g 'daemon off;'"]
