FROM ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97

ARG EARNAPP_VERSION=""
ARG INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
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

# Create expected systemd runtime directories and initrd-release
RUN mkdir -p \
        /run/systemd/system \
        /etc/systemd/system \
        /etc/systemd/system/multi-user.target.wants \
        /lib/systemd/system \
        "$APP_DIR" \
        "$CONFIG_DIR" \
    && touch /etc/initrd-release

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        sudo \
        openssl \
        python3 \
        lsb-release \
    && update-ca-certificates

# Install systemctl replacement
RUN curl -L https://raw.githubusercontent.com/rickyn-croesus/docker-systemctl-replacement/1e9f41ccb25e3e45c4d06439b9fa6f3a7c5a0d0e/files/docker/systemctl3.py \
        -o /usr/bin/systemctl \
    && curl -L https://raw.githubusercontent.com/rickyn-croesus/docker-systemctl-replacement/1e9f41ccb25e3e45c4d06439b9fa6f3a7c5a0d0e/files/docker/hostnamectl3.py \
        -o /usr/bin/hostnamectl \
    && curl -L https://raw.githubusercontent.com/rickyn-croesus/docker-systemctl-replacement/1e9f41ccb25e3e45c4d06439b9fa6f3a7c5a0d0e/files/docker/journalctl3.py \
        -o /usr/bin/journalctl \
    && curl -L https://raw.githubusercontent.com/rickyn-croesus/docker-systemctl-replacement/1e9f41ccb25e3e45c4d06439b9fa6f3a7c5a0d0e/files/docker/loginctl3.py \
        -o /usr/bin/loginctl \
    && curl -L https://raw.githubusercontent.com/rickyn-croesus/docker-systemctl-replacement/1e9f41ccb25e3e45c4d06439b9fa6f3a7c5a0d0e/files/docker/systemd-tmpfiles3.py \
        -o /usr/bin/systemd-tmpfiles \
    && chmod +x \
        /usr/bin/systemctl \
        /usr/bin/hostnamectl \
        /usr/bin/journalctl \
        /usr/bin/loginctl \
        /usr/bin/systemd-tmpfiles

# Install EarnApp via install script
RUN curl -fsSL "$INSTALLER_URL" -o /tmp/earnapp.sh \
    && echo "yes" | bash /tmp/earnapp.sh \
    && rm -f /tmp/earnapp.sh \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

COPY --chmod=755 src/entrypoint.sh /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
