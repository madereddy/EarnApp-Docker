FROM debian:stable-slim@sha256:85dfcffff3c1e193877f143d05eaba8ae7f3f95cb0a32e0bc04a448077e1ac69

ARG TARGETARCH
ARG TARGETVARIANT
ARG EARNAPP_VERSION=""

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/app/src/
ENV BIN_PATH=/usr/bin/earnapp
ENV CONFIG_DIR=/etc/earnapp
ENV INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ENV CDN_BASE=https://cdn-earnapp.b-cdn.net/static
ENV MALLOC_ARENA_MAX=2

# Install curl, download binary, then remove curl to keep image lean (~15MB saved)
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && mkdir -p $APP_DIR $CONFIG_DIR \
    && if [ -z "$EARNAPP_VERSION" ]; then \
        export EARNAPP_VERSION=$(curl -fsSL $INSTALLER_URL | grep VERSION= | cut -d'"' -f2); \
    fi \
    && echo "[INFO] Installing EarnApp version $EARNAPP_VERSION for arch $TARGETARCH/$TARGETVARIANT" \
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
    && echo "[INFO] EarnApp binary downloaded." \
    && apt-get purge -y --auto-remove curl ca-certificates \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fake hostnamectl for EarnApp
RUN echo -e '#!/bin/sh\nhostname' > /usr/bin/hostnamectl && chmod +x /usr/bin/hostnamectl

# Fake lsb_release for EarnApp
RUN echo -e '#!/bin/sh\necho "Distributor ID: Debian"\necho "Description: Debian Bookworm"\necho "Release: 12"\necho "Codename: bookworm"' \
    > /usr/bin/lsb_release && chmod +x /usr/bin/lsb_release

# Copy entrypoint script
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=10s --retries=2 CMD cat /etc/earnapp/status | grep enabled && exit 0 || exit 1
# Persistent configuration
VOLUME ["/etc/earnapp"]

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]