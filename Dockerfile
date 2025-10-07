# Используем Alpine 3.21.0 и явно проверяем/обновляем musl
FROM alpine:3.21.0

# Добавляем репозиторий Nginx mainline и ключи
RUN echo "http://nginx.org/packages/mainline/alpine/v3.21/main" >> /etc/apk/repositories && \
    wget -O /etc/apk/keys/nginx_signing.rsa.pub https://nginx.org/keys/nginx_signing.rsa.pub

# Явно обновляем musl до требуемой версии или выше
RUN apk update && apk upgrade musl && \
    echo "=== Checking musl version ===" && \
    musl_version=$(apk list --installed musl | awk '{print $1}' | cut -d'-' -f2-) && \
    echo "Installed musl version: $musl_version" && \
    if [ "$(printf '%s\n' "1.2.5-r9" "$musl_version" | sort -V | head -n1)" != "1.2.5-r9" ]; then \
        echo "ERROR: musl version $musl_version is lower than required 1.2.5-r9"; \
        exit 1; \
    else \
        echo "✅ musl version meets requirement: $musl_version"; \
    fi

# Создаем non-root пользователя с фиксированным UID/GID
RUN addgroup -S -g 65532 nonroot && \
    adduser -S -D -H -u 65532 -G nonroot nonroot

# Устанавливаем Nginx 1.29.1 и зависимости
RUN apk add --no-cache \
    nginx=1.29.1-r1 \
    gettext-envsubst \
    pcre \
    zlib \
    openssl

# Настраиваем безопасность и логирование
RUN ln -sf /dev/stdout /var/log/nginx/access.log && \
    ln -sf /dev/stderr /var/log/nginx/error.log && \
    \
    # Меняем порт на 8080 \
    sed -i "s,listen       80;,listen       8080;," /etc/nginx/conf.d/default.conf && \
    \
    # Убираем user директиву (будем использовать USER в Dockerfile) \
    sed -i "/user  nginx;/d" /etc/nginx/nginx.conf && \
    \
    # Исправляем путь pid файла \
    sed -i "s,pid        /run/nginx.pid;,pid        /var/run/nginx.pid;," /etc/nginx/nginx.conf && \
    \
    # Отключаем server tokens для безопасности \
    sed -i '/^http {$/a\    server_tokens off;' /etc/nginx/nginx.conf && \
    \
    # Создаем необходимые директории \
    mkdir -p /var/run /var/cache/nginx

# Устанавливаем правильные права
RUN chown -R nonroot:nonroot /var/cache/nginx /etc/nginx /var/run /var/log/nginx && \
    chmod -R g+w /var/cache/nginx /etc/nginx

# Копируем кастомную конфигурацию
COPY nginx-minimal.conf /etc/nginx/nginx.conf

# Копируем статические файлы с правильными правами
COPY --chown=nonroot:nonroot html /usr/share/nginx/html/

# Добавляем health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/health || exit 1

USER nonroot

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
