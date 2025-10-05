FROM alpine:3.20.0 AS builder

WORKDIR /tmp

RUN apk update && apk add --no-cache \
    build-base \
    pcre-dev \
    zlib-dev \
    openssl-dev \
    wget \
    tar

RUN wget --no-verbose -O nginx.tar.gz https://nginx.org/download/nginx-1.24.0.tar.gz && \
    tar -xzf nginx.tar.gz

WORKDIR /tmp/nginx-1.24.0

# Configure nginx to use /tmp for logs during build (avoids permission issues)
RUN ./configure \
    --prefix=/etc/nginx \
    --sbin-path=/usr/sbin/nginx \
    --conf-path=/etc/nginx/nginx.conf \
    --error-log-path=/tmp/error.log \
    --http-log-path=/tmp/access.log \
    --pid-path=/tmp/nginx.pid \
    --user=nginx \
    --group=nginx \
    --with-http_ssl_module && \
    make -j$(nproc) && \
    make install

FROM alpine:3.20.0

RUN apk add --no-cache pcre zlib openssl && \
    addgroup -S nginx && \
    adduser -S -D -H -G nginx nginx && \
    mkdir -p /var/log/nginx /var/www/html /var/run

COPY --from=builder /usr/sbin/nginx /usr/sbin/nginx
COPY --from=builder /etc/nginx /etc/nginx

# Copy your configuration file (make sure it uses correct log paths)
COPY nginx-minimal.conf /etc/nginx/nginx.conf

# Create default HTML content
RUN mkdir -p /var/www/html && \
    echo '<!DOCTYPE html><html><head><title>Welcome to nginx!</title></head><body><h1>Welcome to nginx!</h1><p>If you see this page, the nginx web server is successfully installed and working.</p></body></html>' > /var/www/html/index.html && \
    chown -R nginx:nginx /var/www/html /etc/nginx /var/log/nginx /var/run

# Skip the test during build - test at runtime instead
USER nginx

EXPOSE 8080
CMD ["sh", "-c", "nginx -t && nginx -g 'daemon off;'"]
