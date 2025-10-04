FROM alpine:3.20.0 AS nginx-builder

# Устанавливаем рабочий каталог
WORKDIR /tmp

# Скачиваем и компилируем nginx без ненужных модулей
RUN apk add --no-cache build-base pcre-dev zlib-dev openssl-dev && \
    wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz && \
    cd nginx-1.24.0 && \
    ./configure \
        --prefix=/etc/nginx \
        --sbin-path=/usr/sbin/nginx \
        --modules-path=/usr/lib/nginx/modules \
        --conf-path=/etc/nginx/nginx.conf \
        --error-log-path=/var/log/nginx/error.log \
        --http-log-path=/var/log/nginx/access.log \
        --pid-path=/var/run/nginx.pid \
        --lock-path=/var/run/nginx.lock \
        --http-client-body-temp-path=/var/cache/nginx/client_temp \
        --http-proxy-temp-path=/var/cache/nginx/proxy_temp \
        --http-fastcgi-temp-path=/var/cache/nginx/fastcgi_temp \
        --http-uwsgi-temp-path=/var/cache/nginx/uwsgi_temp \
        --http-scgi-temp-path=/var/cache/nginx/scgi_temp \
        --user=nginx \
        --group=nginx \
        --with-http_ssl_module \
        --with-http_realip_module \
        --with-http_gzip_static_module \
        --without-http_autoindex_module \
        --without-http_ssi_module \
        --without-http_scgi_module \
        --without-http_uwsgi_module \
        --without-http_fastcgi_module && \
    make && make install

FROM alpine:3.20.0

RUN addgroup -S nginx && adduser -S -D -H -G nginx nginx

COPY --from=nginx-builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=nginx-builder /etc/nginx /etc/nginx

RUN mkdir -p /var/log/nginx /var/cache/nginx && \
    chown -R nginx:nginx /var/log/nginx /var/cache/nginx

# Создаем простую конфигурацию nginx прямо в Dockerfile
RUN cat > /etc/nginx/nginx.conf << 'EOF'
user nginx nginx;
worker_processes 1;
pid /var/run/nginx/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    
    server_tokens off;
    
    access_log /var/log/nginx/access.log;
    error_log /var/log/nginx/error.log;
    
    sendfile on;
    tcp_nopush on;
    tcp_nodelay on;
    keepalive_timeout 65;
    
    server {
        listen 8080;
        server_name _;
        root /var/www/html;
        index index.html;
        
        location / {
            try_files $uri $uri/ =404;
        }
    }
}
EOF

COPY --chown=nginx:nginx html /var/www/html

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
