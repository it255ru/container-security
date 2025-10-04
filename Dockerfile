# Используем конкретную версию nginx на Alpine
FROM nginx:1.24.0-alpine

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Production nginx server"

# Создаем non-root пользователя (nginx уже создан в базовом образе, но убедимся)
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/run && \
    chmod -R 755 /var/cache/nginx

# Копируем кастомную конфигурацию nginx
COPY nginx.conf /etc/nginx/nginx.conf
COPY default.conf /etc/nginx/conf.d/default.conf

# Копируем статические файлы
COPY --chown=appuser:appgroup html /usr/share/nginx/html

# Переключаемся на non-root пользователя
USER appuser

# Открываем порт (nginx будет слушать на 8080 для non-root пользователя)
EXPOSE 8080

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]
