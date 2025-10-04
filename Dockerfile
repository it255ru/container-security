FROM nginx:1.24-alpine

# Создаем non-root пользователя
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -D -H -u 1001 -G appgroup appuser

# Настраиваем права
RUN chown -R appuser:appgroup /var/cache/nginx

# Копируем файлы
COPY --chown=appuser:appgroup html /usr/share/nginx/html

# Используем non-root пользователя
USER appuser

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
