FROM ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97

ARG EARNAPP_VERSION=""
ARG INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ARG CDN_BASE=https://cdn-earnapp.b-cdn.net/static
ARG TARGETARCH
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

# Install dependencies and update CA certs
RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        wget \
        git \
        sudo \
        openssl \
        python3 \
        lsb-release \
    && update-ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Install systemctl replacement
RUN git clone --depth=1 https://github.com/gdraheim/docker-systemctl-replacement.git /tmp/systemctl-replacement \
    && cp /tmp/systemctl-replacement/files/docker/systemctl3.py        /usr/bin/systemctl \
    && cp /tmp/systemctl-replacement/files/docker/hostnamectl3.py      /usr/bin/hostnamectl \
    && cp /tmp/systemctl-replacement/files/docker/journalctl3.py       /usr/bin/journalctl \
    && cp /tmp/systemctl-replacement/files/docker/loginctl3.py         /usr/bin/loginctl \
    && cp /tmp/systemctl-replacement/files/docker/systemd-tmpfiles3.py /usr/bin/systemd-tmpfiles \
    && chmod +x \
        /usr/bin/systemctl \
        /usr/bin/hostnamectl \
        /usr/bin/journalctl \
        /usr/bin/loginctl \
        /usr/bin/systemd-tmpfiles \
    && rm -rf /tmp/systemctl-replacement

# Install EarnApp binary
RUN mkdir -p "$APP_DIR" "$CONFIG_DIR" /run/systemd/system \
    && if [ -z "$EARNAPP_VERSION" ]; then \
        EARNAPP_VERSION=$(curl -fsSL "$INSTALLER_URL" | grep VERSION= | cut -d'"' -f2); \
    fi \
    && echo "[INFO] Installing EarnApp $EARNAPP_VERSION for $TARGETARCH" \
    && if [ "$TARGETARCH" = "amd64" ]; then \
        FILE="earnapp-x64-$EARNAPP_VERSION"; \
    elif [ "$TARGETARCH" = "arm64" ]; then \
        FILE="earnapp-aarch64-$EARNAPP_VERSION"; \
    elif [ "$TARGETARCH" = "arm" ]; then \
        FILE="earnapp-arm7l-$EARNAPP_VERSION"; \
    else \
        echo "[ERROR] Unsupported architecture: $TARGETARCH"; exit 1; \
    fi \
    && echo "[INFO] Downloading $FILE" \
    && curl -fL "$CDN_BASE/$FILE" -o "$BIN_PATH" \
    && chmod +x "$BIN_PATH" \
    && apt-get purge -y --auto-remove curl git \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
