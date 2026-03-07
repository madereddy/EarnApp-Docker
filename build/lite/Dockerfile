FROM debian:bookworm-slim@sha256:74d56e3931e0d5a1dd51f8c8a2466d21de84a271cd3b5a733b803aa91abf4421

ARG EARNAPP_VERSION=""
ARG INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ARG CDN_BASE=https://cdn-earnapp.b-cdn.net/static
ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/app/src/
ENV BIN_PATH=/usr/bin/earnapp
ENV CONFIG_DIR=/etc/earnapp
ENV MALLOC_ARENA_MAX=2

# OCI labels description is overridden for test builds via the workflow
LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/madereddy/EarnApp-Docker" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Unofficial containerized EarnApp by BrightData"

# Install curl, download binary, then remove curl to keep image lean (~15MB saved)
# Kept CA Certs to reduce random TLS errors at runtime
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates dbus \
    && mkdir -p "$APP_DIR" "$CONFIG_DIR" \
    && if [ -z "$EARNAPP_VERSION" ]; then \
        EARNAPP_VERSION=$(curl -fsSL "$INSTALLER_URL" | grep VERSION= | cut -d'"' -f2); \
    fi \
    && ARCH=$(uname -m) \
    && echo "[INFO] Installing EarnApp $EARNAPP_VERSION for $ARCH" \
    && if [ "$ARCH" = "x86_64" ]; then \
        FILE="earnapp-x64-$EARNAPP_VERSION"; \
    elif [ "$ARCH" = "aarch64" ]; then \
        FILE="earnapp-aarch64-$EARNAPP_VERSION"; \
    elif [ "$ARCH" = "armv7l" ]; then \
        FILE="earnapp-arm7l-$EARNAPP_VERSION"; \
    else \
        echo "[ERROR] Unsupported architecture: $ARCH"; exit 1; \
    fi \
    && echo "[INFO] Downloading $FILE" \
    && curl -fL "$CDN_BASE/$FILE" -o "$BIN_PATH" \
    && chmod +x "$BIN_PATH" \
    && apt-get purge -y --auto-remove curl \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# Fake hostnamectl + lsb_release so EarnApp runs in a minimal Debian environment
# Generate these dynamically now so future builds will be auto updated instead of hardcoding values. 
RUN printf '#!/bin/sh\nhostname\n' > /usr/bin/hostnamectl \
    && chmod +x /usr/bin/hostnamectl \
    && . /etc/os-release \
    && printf '#!/bin/sh\necho "Distributor ID: Debian"\necho "Description: %s"\necho "Release: %s"\necho "Codename: %s"\n' \
       "$PRETTY_NAME" "$VERSION_ID" "$VERSION_CODENAME" \
       > /usr/bin/lsb_release \
    && chmod +x /usr/bin/lsb_release

COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
