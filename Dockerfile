FROM alpine:3.20.0

# Устанавливаем nginx из репозитория
RUN apk add --no-cache nginx

# Создаем non-root пользователя
RUN addgroup -S nginx && adduser -S -D -H -G nginx nginx

# Создаем необходимые директории
RUN mkdir -p /var/log/nginx /var/cache/nginx /var/www/html && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx /var/www/html

# Копируем конфигурацию
COPY nginx-minimal.conf /etc/nginx/nginx.conf

# Копируем статические файлы
COPY --chown=nginx:nginx html /var/www/html

# Переключаемся на non-root пользователя
USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
