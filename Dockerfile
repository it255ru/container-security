# Используем минимальный образ Alpine и устанавливаем nginx вручную с фиксированными версиями
FROM alpine:3.20.0 AS builder

# Устанавливаем метаданные
LABEL maintainer="security-team@example.com"
LABEL description="Ultra-secure nginx server"

# Устанавливаем конкретные версии пакетов и обновляем систему
RUN apk add --no-cache --update \
    nginx=1.24.0-r12 \
    openssl=3.3.1-r0 \
    && apk upgrade --no-cache --available \
    && rm -rf /var/cache/apk/*

# Создаем необходимые директории
RUN mkdir -p /var/run/nginx /var/tmp/nginx /var/log/nginx /var/www/html \
    && chmod -R 755 /var/run/nginx /var/tmp/nginx /var/log/nginx

# Создаем non-root пользователя
RUN addgroup -g 1001 -S nginxgroup && \
    adduser -S -D -H -u 1001 -G nginxgroup -s /sbin/nologin nginxuser

# Копируем минимальную конфигурацию
COPY nginx-minimal.conf /etc/nginx/nginx.conf
COPY --chown=nginxuser:nginxgroup index.html /var/www/html/index.html

# Устанавливаем правильные права
RUN chown -R nginxuser:nginxgroup /var/run/nginx /var/tmp/nginx /var/log/nginx /etc/nginx /var/www/html

# Финальный образ - используем distroless или scratch для максимальной безопасности
FROM gcr.io/distroless/static:nonroot

# Копируем только необходимые бинарные файлы из builder стадии
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx
COPY --from=builder /var/www/html /var/www/html
COPY --from=builder /var/run/nginx /var/run/nginx
COPY --from=builder /var/tmp/nginx /var/tmp/nginx
COPY --from=builder /var/log/nginx /var/log/nginx
COPY --from=builder /lib/ld-musl-x86_64.so.1 /lib/ld-musl-x86_64.so.1
COPY --from=builder /usr/lib/libcrypto.so.3 /usr/lib/libcrypto.so.3
COPY --from=builder /usr/lib/libssl.so.3 /usr/lib/libssl.so.3
COPY --from=builder /usr/lib/libz.so.1 /usr/lib/libz.so.1
COPY --from=builder /usr/lib/libpcre2-8.so.0 /usr/lib/libpcre2-8.so.0

# Порт для non-root пользователя
EXPOSE 8080

# Запускаем nginx
CMD ["/usr/sbin/nginx", "-g", "daemon off;"]
