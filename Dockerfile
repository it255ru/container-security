# Используем официальный образ nginx
FROM nginx:1.24-alpine

# Устанавливаем метаданные
LABEL maintainer="your-email@example.com"
LABEL description="Production nginx server"

# Копируем статические файлы
COPY html /usr/share/nginx/html

# Переключаемся на non-root пользователя (nginx уже существует в официальном образе)
USER nginx

# Открываем порт
EXPOSE 8080

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]
