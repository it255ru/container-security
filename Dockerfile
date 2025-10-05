FROM alpine:3.20.0 AS builder

WORKDIR /tmp

# Install build dependencies with explicit updates
RUN apk update && apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar \
    curl

# Download and extract nginx with better error handling
RUN wget --no-verbose -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz && \
    ls -la

WORKDIR /tmp/nginx-1.24.0

# Configure nginx with minimal modules
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --without-http_rewrite_module \
    --without-http_gzip_module

# Build and install
RUN make -j$(nproc) && make install

FROM alpine:3.20.0

# Install only essential runtime dependencies
RUN apk update && apk add --no-cache \
    pcre \
    zlib \
    openssl

# Create nginx user and directories
RUN addgroup -S nginx && \
    adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html /var/run && \
    chown -R nginx:nginx /var/log/nginx /var/www/html

# Copy nginx binary
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

# Create basic nginx.conf if not provided
RUN if [ ! -f /etc/nginx/nginx.conf ]; then \
    cat > /etc/nginx/nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;
    sendfile on;
    keepalive_timeout 65;

    server {
        listen 8080;
        server_name _;
        root /var/www/html;
        
        location / {
            try_files $uri $uri/ =404;
        }
    }
}
EOF
    fi

# Create default index.html if not provided
RUN if [ ! -f /var/www/html/index.html ]; then \
    mkdir -p /var/www/html && \
    cat > /var/www/html/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Welcome to nginx!</title>
</head>
<body>
    <h1>Welcome to nginx!</h1>
    <p>If you see this page, the nginx web server is successfully installed and working.</p>
</body>
</html>
EOF
    fi

# Set permissions
RUN chown -R nginx:nginx /etc/nginx /var/www/html

# Test configuration
USER nginx
RUN nginx -t

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
