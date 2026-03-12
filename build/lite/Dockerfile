FROM ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97

ARG EARNAPP_VERSION=""
ARG INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ARG CDN_BASE=https://cdn-earnapp.b-cdn.net/static
ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker
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

# Install dependencies, systemctl replacement, and EarnApp binary
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        wget \
        sudo \
        openssl \
        python3 \
        lsb-release \
    && update-ca-certificates \
    && mkdir -p "$APP_DIR" "$CONFIG_DIR" /run/systemd/system \
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

# Install systemctl replacement and remove shell stubs no longer needed
ARG SYSTEMCTL_REPO=https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/master/files/docker
RUN wget -q "$SYSTEMCTL_REPO/systemctl3.py"      -O /usr/bin/systemctl \
    && wget -q "$SYSTEMCTL_REPO/hostnamectl3.py"  -O /usr/bin/hostnamectl \
    && wget -q "$SYSTEMCTL_REPO/journalctl3.py"   -O /usr/bin/journalctl \
    && wget -q "$SYSTEMCTL_REPO/loginctl3.py"     -O /usr/bin/loginctl \
    && wget -q "$SYSTEMCTL_REPO/systemd-tmpfiles3.py" -O /usr/bin/systemd-tmpfiles \
    && chmod +x \
        /usr/bin/systemctl \
        /usr/bin/hostnamectl \
        /usr/bin/journalctl \
        /usr/bin/loginctl \
        /usr/bin/systemd-tmpfiles

COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
