FROM debian:stable-slim@sha256:85dfcffff3c1e193877f143d05eaba8ae7f3f95cb0a32e0bc04a448077e1ac69

ARG TARGETARCH
ARG TARGETVARIANT
ARG EARNAPP_VERSION=""
ARG INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ARG CDN_BASE=https://cdn-earnapp.b-cdn.net/static

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/app/src/
ENV BIN_PATH=/usr/bin/earnapp
ENV CONFIG_DIR=/etc/earnapp
ENV MALLOC_ARENA_MAX=2

# Install curl, download binary, then remove curl to keep image lean (~15MB saved)
# Kept CA Certs to reduce random tls errors
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && mkdir -p "$APP_DIR" "$CONFIG_DIR" \
    && if [ -z "$EARNAPP_VERSION" ]; then \
        EARNAPP_VERSION=$(curl -fsSL "$INSTALLER_URL" | grep VERSION= | cut -d'"' -f2); \
    fi \
    && echo "[INFO] Installing EarnApp $EARNAPP_VERSION for $TARGETARCH/$TARGETVARIANT" \
    && case "$TARGETARCH" in \
        amd64) FILE="earnapp-x64-$EARNAPP_VERSION" ;; \
        arm64) FILE="earnapp-aarch64-$EARNAPP_VERSION" ;; \
        arm) \
            case "$TARGETVARIANT" in \
                v7|v6) FILE="earnapp-arm7l-$EARNAPP_VERSION" ;; \
                *) echo "[ERROR] Unsupported ARM variant: $TARGETVARIANT"; exit 1 ;; \
            esac ;; \
        *) echo "[ERROR] Unsupported architecture: $TARGETARCH"; exit 1 ;; \
    esac \
    && curl -fL "$CDN_BASE/$FILE" -o "$BIN_PATH" \
    && chmod +x "$BIN_PATH" \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fake hostnamectl + Fake lsb_release - combining dockerfile layers
RUN printf '#!/bin/sh\nhostname\n' > /usr/bin/hostnamectl \
    && chmod +x /usr/bin/hostnamectl \
    && printf '#!/bin/sh\necho "Distributor ID: Debian"\necho "Description: Debian Bookworm"\necho "Release: 12"\necho "Codename: bookworm"\n' \
       > /usr/bin/lsb_release \
    && chmod +x /usr/bin/lsb_release

# Copy entrypoint script
COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

# Persistent configuration
VOLUME ["/etc/earnapp"]

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
