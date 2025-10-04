# Используем конкретную версию nginx на Alpine
FROM nginx:1.24.0-alpine

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Secure nginx server"

# Создаем non-root пользователя и настраиваем nginx в одном RUN
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup && \
    chown -R appuser:appgroup /var/cache/nginx && \
    chown -R appuser:appgroup /var/run && \
    sed -i 's/listen.*80;/listen 8080;/' /etc/nginx/conf.d/default.conf && \
    chmod -R 755 /var/cache/nginx

# Копируем статические файлы
COPY --chown=appuser:appgroup html /usr/share/nginx/html

# Переключаемся на non-root пользователя
USER appuser

# Открываем порт
EXPOSE 8080

# Запускаем nginx (только одна CMD инструкция)
CMD ["nginx", "-g", "daemon off;"]
