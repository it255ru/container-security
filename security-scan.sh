#!/bin/sh
set -e

echo "🔒 Running security checks..."

# Проверяем, что контейнер запущен от non-root пользователя
if [ "$(id -u)" = "0" ]; then
    echo "❌ Container is running as root!"
    exit 1
fi

# Проверяем, что нет SUID битов в критических местах
find / -perm -4000 -type f 2>/dev/null | grep -v -E '(busybox|nginx)' && {
    echo "❌ Dangerous SUID files found!"
    exit 1
}

# Проверяем, что порт не привилегированный
if [ "$(cat /etc/nginx/conf.d/default.conf | grep 'listen 8080')" = "" ]; then
    echo "❌ Nginx is not configured for non-privileged port!"
    exit 1
}

echo "✅ All security checks passed"
