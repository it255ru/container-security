# Используем конкретную версию Alpine с минимальным набором пакетов
FROM alpine:3.20.0 AS builder

# Устанавливаем метаданные
LABEL maintainer="security-team@example.com"
LABEL description="Hardened nginx server"

# Устанавливаем только необходимые пакеты и обновляем систему
RUN apk add --no-cache --update \
    nginx=1.24.0-r12 \
    && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/*

# Создаем необходимые директории с правильными правами
RUN mkdir -p /var/run/nginx /var/tmp/nginx /var/log/nginx \
    && chmod -R 755 /var/run/nginx /var/tmp/nginx /var/log/nginx

# Копируем кастомную конфигурацию безопасности
COPY nginx-security.conf /etc/nginx/nginx.conf
COPY security-headers.conf /etc/nginx/conf.d/security-headers.conf
COPY default-secure.conf /etc/nginx/conf.d/default.conf

# Создаем non-root пользователя и группу
RUN addgroup -g 1001 -S nginxgroup && \
    adduser -S -D -H -u 1001 -G nginxgroup -s /sbin/nologin -g 'nginx user' nginxuser && \
    chown -R nginxuser:nginxgroup /var/run/nginx /var/tmp/nginx /var/log/nginx /etc/nginx

# Создаем простую статическую страницу
RUN echo '<!DOCTYPE html><html><head><title>Secure Server</title></head><body><h1>Secure Nginx</h1></body></html>' > /var/www/html/index.html

# Финальный образ - multi-stage для уменьшения поверхности атаки
FROM alpine:3.20.0

# Устанавливаем только необходимые runtime пакеты
RUN apk add --no-cache --update \
    nginx=1.24.0-r12 \
    tzdata \
    && apk upgrade --no-cache \
    && rm -rf /var/cache/apk/* \
    && addgroup -g 1001 -S nginxgroup \
    && adduser -S -D -H -u 1001 -G nginxgroup -s /sbin/nologin -g 'nginx user' nginxuser

# Копируем только необходимые файлы из builder стадии
COPY --from=builder --chown=nginxuser:nginxgroup /etc/nginx /etc/nginx
COPY --from=builder --chown=nginxuser:nginxgroup /var/www/html /var/www/html
COPY --from=builder --chown=nginxuser:nginxgroup /var/run/nginx /var/run/nginx
COPY --from=builder --chown=nginxuser:nginxgroup /var/tmp/nginx /var/tmp/nginx
COPY --from=builder --chown=nginxuser:nginxgroup /var/log/nginx /var/log/nginx

# Устанавливаем правильные права
RUN chmod -R 755 /var/run/nginx /var/tmp/nginx /var/log/nginx /etc/nginx \
    && chmod 644 /etc/nginx/nginx.conf /etc/nginx/conf.d/*.conf \
    && find /var/www/html -type f -exec chmod 644 {} \; \
    && find /var/www/html -type d -exec chmod 755 {} \;

# Переключаемся на non-root пользователя
USER nginxuser

# Открываем порт
EXPOSE 8080

COPY security-scan.sh /usr/local/bin/security-scan.sh
RUN chmod +x /usr/local/bin/security-scan.sh

# Запускаем проверки безопасности при старте
CMD ["sh", "-c", "/usr/local/bin/security-scan.sh && nginx -g 'daemon off;'"]

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]
