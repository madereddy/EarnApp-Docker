# Base stage: heavy OS + dependencies
FROM ubuntu:22.04 AS base

ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies with BuildKit cache mounts
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt/lists,sharing=locked \
    apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        wget \
        sudo \
        openssl \
        python3 \
        lsb-release \
    && update-ca-certificates \
    && apt-get autoremove -y --purge \
    && apt-get clean

# Create common directories (stable layer)
RUN mkdir -p \
        /run/systemd/system \
        /etc/systemd/system \
        /etc/systemd/system/multi-user.target.wants \
        /lib/systemd/system \
        /app/src/ \
        /etc/earnapp \
    && touch /etc/initrd-release \
    && touch /usr/bin/loginctl \
    && touch /usr/bin/systemd-tmpfiles

# Final stage: copy scripts & set runtime ENV
FROM base AS final

ARG EARNAPP_VERSION
ARG BUILD_DATE
ARG VCS_REF

ENV container=docker \
    APP_DIR=/app/src/ \
    BIN_PATH=/usr/bin/earnapp \
    CONFIG_DIR=/etc/earnapp \
    MALLOC_ARENA_MAX=2 \
    INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh \
    CDN_BASE=https://cdn-earnapp.b-cdn.net/static \
    EARNAPP_VERSION=${EARNAPP_VERSION}

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/madereddy/EarnApp-Docker" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Unofficial containerized EarnApp by BrightData"

# Copy static scripts (rarely changed → cacheable)
COPY --chmod=755 src/systemctl3.py   /usr/bin/systemctl
COPY --chmod=755 src/hostnamectl3.py /usr/bin/hostnamectl
COPY --chmod=755 src/journalctl3.py  /usr/bin/journalctl
COPY --chmod=755 src/entrypoint.sh   /entrypoint.sh

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
