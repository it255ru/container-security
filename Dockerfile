FROM nginx:1.24-alpine

# Явно создаем non-root пользователя (даже если он уже есть)
RUN addgroup -g 1001 -S appgroup && \
    adduser -S -D -H -u 1001 -G appgroup appuser && \
    chown -R appuser:appgroup /var/cache/nginx

# Копируем статические файлы
COPY --chown=appuser:appgroup html /usr/share/nginx/html

# Явно переключаемся на non-root пользователя
USER appuser

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
