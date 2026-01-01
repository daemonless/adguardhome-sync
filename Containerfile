ARG BASE_VERSION=15
FROM ghcr.io/daemonless/base:${BASE_VERSION}

ARG FREEBSD_ARCH=amd64
ARG UPSTREAM_URL="https://api.github.com/repos/bakito/adguardhome-sync/releases/latest"
ARG UPSTREAM_JQ=".tag_name"
ARG HEALTHCHECK_ENDPOINT="http://localhost:8080"

ENV HEALTHCHECK_URL="${HEALTHCHECK_ENDPOINT}"

LABEL org.opencontainers.image.title="AdGuardHome Sync" \
    org.opencontainers.image.description="Sync AdGuardHome config to replica instances on FreeBSD" \
    org.opencontainers.image.source="https://github.com/daemonless/adguardhome-sync" \
    org.opencontainers.image.url="https://github.com/bakito/adguardhome-sync" \
    org.opencontainers.image.documentation="https://github.com/bakito/adguardhome-sync" \
    org.opencontainers.image.licenses="Apache-2.0" \
    org.opencontainers.image.vendor="daemonless" \
    org.opencontainers.image.authors="daemonless" \
    io.daemonless.port="8080" \
    io.daemonless.arch="${FREEBSD_ARCH}" \
    io.daemonless.category="Network" \
    io.daemonless.upstream-url="${UPSTREAM_URL}" \
    io.daemonless.upstream-jq="${UPSTREAM_JQ}" \
    io.daemonless.healthcheck-url="${HEALTHCHECK_ENDPOINT}"

# Build adguardhome-sync from source
RUN pkg install -y go git && \
    mkdir -p /app && \
    VERSION=$(fetch -qo - "${UPSTREAM_URL}" | jq -r '.tag_name') && \
    echo "Building AdGuardHome Sync ${VERSION}" && \
    git clone --depth 1 --branch "${VERSION}" https://github.com/bakito/adguardhome-sync.git /tmp/src && \
    cd /tmp/src && \
    CGO_ENABLED=0 go build -ldflags="-s -w -X github.com/bakito/adguardhome-sync/version.Version=${VERSION}" -o /usr/local/bin/adguardhome-sync . && \
    chmod +x /usr/local/bin/adguardhome-sync && \
    echo "${VERSION}" > /app/version && \
    # Cleanup
    rm -rf /tmp/src /root/go && \
    pkg remove -y go git && \
    pkg autoremove -y && \
    rm -rf /var/cache/pkg/*

# Copy service definition
COPY root/ /

EXPOSE 8080/tcp

VOLUME ["/config"]
