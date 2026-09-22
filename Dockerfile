# ==============================================================================
# STAGE 1: Builder
# ==============================================================================
FROM golang:1.24-bookworm AS builder

ARG NGINX_VERSION=1.26.3

# Install all essential build tools
RUN apt-get update && apt-get install -y \
    build-essential \
    libpcre2-dev \
    zlib1g-dev \
    libssl-dev \
    autoconf \
    automake \
    libtool \
    pkg-config \
    git \
    curl

WORKDIR /src

# 1. Build and install libcoraza
RUN git clone --depth 1 https://github.com/corazawaf/libcoraza.git && \
    cd libcoraza && \
    ./build.sh && \
    ./configure --prefix=/usr/local && \
    make libcoraza.so && \
    mkdir -p /usr/local/include/coraza && \
    cp coraza/coraza.h /usr/local/include/coraza/ && \
    cp libcoraza.so /usr/local/lib/ && \
    ldconfig

# 2. Download matching Nginx source & Coraza Nginx Connector
RUN curl -sO http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz && \
    tar -zxvf nginx-${NGINX_VERSION}.tar.gz && \
    git clone --depth 1 https://github.com/corazawaf/coraza-nginx.git

# 3. Build only the dynamic Nginx module
RUN cd nginx-${NGINX_VERSION} && \
    ./configure --with-compat \
        --with-cc-opt="-I/usr/local/include" \
        --with-ld-opt="-L/usr/local/lib" \
        --add-dynamic-module=/src/coraza-nginx && \
    make -j$(nproc) modules

# 4. Clone OWASP Core Rule Set (CRS)
RUN git clone --depth 1 https://github.com/coreruleset/coreruleset.git /tmp/coreruleset && \
    cp /tmp/coreruleset/crs-setup.conf.example /tmp/coreruleset/crs-setup.conf

# ==============================================================================
# STAGE 2: Production Runtime
# ==============================================================================
FROM nginx:1.26.3-bookworm

# Copy compiled shared library and Nginx module from Stage 1
COPY --from=builder /usr/local/lib/libcoraza.so /usr/local/lib/
COPY --from=builder /src/nginx-1.26.3/objs/ngx_http_coraza_module.so /etc/nginx/modules/
COPY --from=builder /tmp/coreruleset /etc/nginx/coraza/coreruleset/

# Update linker cache so Nginx finds libcoraza.so
RUN echo "/usr/local/lib" > /etc/ld.so.conf.d/coraza.conf && ldconfig

# Copy our configuration files
COPY config/nginx.conf /etc/nginx/nginx.conf
COPY config/coraza.conf /etc/nginx/coraza/coraza.conf

# Add custom styled landing page
RUN echo '<h1>RazOps WAF Gateway - Protected by OWASP Coraza</h1>' > /usr/share/nginx/html/index.html

EXPOSE 80
STOPSIGNAL SIGQUIT
CMD ["nginx", "-g", "daemon off;"]
