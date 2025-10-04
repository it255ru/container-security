# Используем официальный образ nginx с конкретной версией
FROM nginx:1.24-alpine

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Production nginx server"

# Создаем non-root пользователя (nginx уже создан в базовом образе)
RUN chown -R nginx:nginx /var/cache/nginx && \
    sed -i 's/listen.*80;/listen 8080;/' /etc/nginx/conf.d/default.conf

# Копируем статические файлы
COPY --chown=nginx:nginx html /usr/share/nginx/html

# Переключаемся на non-root пользователя (nginx уже существует в образе)
USER nginx

# Открываем порт
EXPOSE 8080

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]
