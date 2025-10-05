FROM alpine:3.20.0 AS builder

WORKDIR /tmp

# Install build dependencies
RUN apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar

# Download and extract nginx
RUN wget --progress=dot:giga -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz

WORKDIR /tmp/nginx-1.24.0

# Configure and build nginx
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --modules-path=/usr/lib/nginx/modules \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/var/log/nginx/error.log \
    --http-log-path=/var/log/nginx/access.log \
    --pid-path=/var/run/nginx.pid \
    --lock-path=/var/run/nginx.lock \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module \
    --without-http_rewrite_module && \
    make -j$(nproc) && \
    make install

FROM alpine:3.20.0

# Install runtime dependencies
RUN apk add --no-cache \
    pcre \
    zlib \
    openssl && \
    addgroup -S nginx && \
    adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html /var/cache/nginx /var/run && \
    chown -R nginx:nginx /var/log/nginx /var/www/html /var/cache/nginx /var/run

# Copy nginx binary and configuration from builder stage
COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

# Create necessary directories and set permissions
RUN mkdir -p /etc/nginx/conf.d && \
    chown -R nginx:nginx /etc/nginx

# Copy custom configuration and static files
COPY nginx-minimal.conf /etc/nginx/nginx.conf
COPY --chown=nginx:nginx html /var/www/html

# Verify nginx binary works
RUN nginx -t

USER nginx
EXPOSE 8080

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
