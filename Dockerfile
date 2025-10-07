FROM nginx:1.28.0-alpine-slim

ENV NJS_VERSION=0.8.10
ENV PKG_RELEASE=1
ENV DYNPKG_RELEASE=1

RUN set -eux; \
    apkArch="$(cat /etc/apk/arch)"; \
    nginxPackages=" \
        nginx=${NGINX_VERSION}-r${PKG_RELEASE} \
        nginx-module-njs=${NGINX_VERSION}.${NJS_VERSION}-r${PKG_RELEASE} \
    "; \
    \
    case "$apkArch" in \
        x86_64|aarch64) \
            apk add -X "https://nginx.org/packages/alpine/v$(egrep -o '^[0-9]+\.[0-9]+' /etc/alpine-release)/main" \
                --no-cache --virtual .nginx-deps $nginxPackages \
            ;; \
        *) \
            echo "Building from source for architecture: $apkArch"; \
            tempDir="$(mktemp -d)"; \
            chown nobody:nobody "$tempDir"; \
            apk add --no-cache --virtual .build-deps \
                gcc \
                libc-dev \
                make \
                openssl-dev \
                pcre2-dev \
                zlib-dev \
                linux-headers \
                curl \
            ; \
            su nobody -s /bin/sh -c " \
                export HOME='$tempDir'; \
                cd '$tempDir'; \
                curl -f -L -O "https://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz"; \
                tar -xzf "nginx-${NGINX_VERSION}.tar.gz"; \
                cd "nginx-${NGINX_VERSION}"; \
                ./configure \
                    --prefix=/etc/nginx \
                    --sbin-path=/usr/sbin/nginx \
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
                    --with-http_addition_module \
                    --with-http_sub_module \
                    --with-http_dav_module \
                    --with-http_flv_module \
                    --with-http_mp4_module \
                    --with-http_gunzip_module \
                    --with-http_gzip_static_module \
                    --with-http_random_index_module \
                    --with-http_secure_link_module \
                    --with-http_stub_status_module \
                    --with-http_auth_request_module \
                    --with-threads \
                    --with-stream \
                    --with-stream_ssl_module \
                    --with-stream_ssl_preread_module \
                    --with-stream_realip_module \
                    --with-http_slice_module \
                    --with-mail \
                    --with-mail_ssl_module \
                    --with-compat \
                    --with-file-aio \
                    --with-http_v2_module; \
                make -j\"$(nproc)\"; \
                make install; \
            "; \
            apk del --no-network .build-deps; \
            rm -rf "$tempDir" /etc/nginx/html/ /var/cache/nginx/*; \
            ;; \
    esac; \
    \
    apk del --no-network .nginx-deps 2>/dev/null || true; \
    rm -rf /var/cache/apk/*;

RUN mkdir -p /var/cache/nginx/client_temp /var/cache/nginx/proxy_temp \
             /var/cache/nginx/fastcgi_temp /var/cache/nginx/uwsgi_temp \
             /var/cache/nginx/scgi_temp; \
    chown -R nginx:nginx /var/cache/nginx; \
    chmod -R 755 /var/cache/nginx;

COPY nginx-minimal.conf /etc/nginx/nginx.conf

COPY --chown=nginx:nginx html /usr/share/nginx/html/

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:8080/ || exit 1

USER nginx

EXPOSE 8080

CMD ["nginx", "-g", "daemon off;"]
