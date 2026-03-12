FROM ubuntu:22.04@sha256:0e5e4a57c2499249aafc3b40fcd541e9a456aab7296681a3994d631587203f97

ARG BUILD_DATE
ARG VCS_REF
ARG EARNAPP_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker
ENV APP_DIR=/app/src/
ENV BIN_PATH=/usr/bin/earnapp
ENV CONFIG_DIR=/etc/earnapp
ENV MALLOC_ARENA_MAX=2
ENV INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ENV CDN_BASE=https://cdn-earnapp.b-cdn.net/static
ENV EARNAPP_VERSION=${EARNAPP_VERSION}

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
    && touch /etc/initrd-release \
    && touch /usr/bin/loginctl \
    && touch /usr/bin/systemd-tmpfiles

# Install dependencies
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
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
    && apt-get clean \
    && apt-get autoremove --purge

COPY --chmod=755 src/systemctl3.py   /usr/bin/systemctl
COPY --chmod=755 src/hostnamectl3.py /usr/bin/hostnamectl
COPY --chmod=755 src/journalctl3.py  /usr/bin/journalctl
COPY --chmod=755 src/entrypoint.sh   /entrypoint.sh

HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
