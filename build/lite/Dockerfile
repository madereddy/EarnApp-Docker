# Base stage: OS + dependencies
FROM ubuntu/python:3.10-22.04_stable AS base

ARG BUILD_DATE
ARG VCS_REF

ENV DEBIAN_FRONTEND=noninteractive \
    APP_DIR=/app/src/ \
    BIN_PATH=/usr/bin/earnapp \
    CONFIG_DIR=/etc/earnapp \
    MALLOC_ARENA_MAX=2 \
    INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh \
    CDN_BASE=https://cdn-earnapp.b-cdn.net/static

# Install dependencies
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

# Create system directories
RUN mkdir -p /run/systemd/system /etc/systemd/system /etc/systemd/system/multi-user.target.wants /lib/systemd/system \
    "$APP_DIR" "$CONFIG_DIR" \
    && touch /etc/initrd-release /usr/bin/loginctl /usr/bin/systemd-tmpfiles

# Build stage: patch installer & pre-download binary
FROM base AS build

ARG EARNAPP_VERSION
ARG PRODUCT="earnapp"

# Patch installer to use build-time version
RUN curl -fsSL "$INSTALLER_URL" \
    | sed "s/^VERSION=\"[^\"]*\"/VERSION=\"$EARNAPP_VERSION\"/" \
    | bash -s -- "$PRODUCT"

# Copy installed binary to a known location
RUN cp /usr/bin/earnapp /usr/local/bin/earnapp

# Final stage: runtime image
FROM base AS final

ARG BUILD_DATE
ARG VCS_REF
ARG EARNAPP_VERSION

ENV container=docker \
    EARNAPP_VERSION=${EARNAPP_VERSION}

LABEL org.opencontainers.image.created=$BUILD_DATE \
      org.opencontainers.image.revision=$VCS_REF \
      org.opencontainers.image.source="https://github.com/madereddy/EarnApp-Docker" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.description="Unofficial containerized EarnApp by BrightData"

# Copy static scripts
COPY --chmod=755 src/systemctl3.py   /usr/bin/systemctl
COPY --chmod=755 src/hostnamectl3.py /usr/bin/hostnamectl
COPY --chmod=755 src/journalctl3.py  /usr/bin/journalctl
COPY --chmod=755 src/entrypoint.sh   /entrypoint.sh

# Copy pre-downloaded binary from build stage
COPY --from=build /usr/local/bin/earnapp /usr/bin/earnapp

# Healthcheck
HEALTHCHECK --interval=1m --timeout=10s --start-period=30s --retries=3 \
  CMD grep -q "enabled" /etc/earnapp/status || exit 1

VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
