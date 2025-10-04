# Базовый образ с последними обновлениями безопасности
FROM alpine:3.20.0

# Устанавливаем метаданные
LABEL maintainer="security-team@example.com"
LABEL description="Secure nginx with updated packages"

# Обновляем все пакеты до последних версий с исправлениями безопасности
RUN apk update && \
    apk upgrade --no-cache && \
    apk add --no-cache \
    nginx=1.24.0-r13 \
    openssl=3.3.2-r0 \
    && rm -rf /var/cache/apk/*

# Создаем non-root пользователя и настраиваем nginx
RUN addgroup -g 1001 -S nginxgroup && \
    adduser -S -D -H -u 1001 -G nginxgroup -s /sbin/nologin nginxuser && \
    mkdir -p /var/run/nginx /var/tmp/nginx /var/log/nginx && \
    chown -R nginxuser:nginxgroup /var/run/nginx /var/tmp/nginx /var/log/nginx && \
    sed -i 's/^user.*/user nginxuser nginxgroup;/' /etc/nginx/nginx.conf && \
    sed -i 's/listen.*80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    chmod -R 755 /var/run/nginx /var/tmp/nginx /var/log/nginx

# Удаляем ненужные пакеты, которые могут содержать уязвимости
RUN apk del --no-cache curl wget

# Копируем статические файлы
COPY --chown=nginxuser:nginxgroup html /usr/share/nginx/html

# Переключаемся на non-root пользователя
USER nginxuser

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
