# --------------------------
# Stage 1: Builder
# --------------------------
FROM --platform=$BUILDPLATFORM debian:bookworm-slim@sha256:56ff6d36d4eb3db13a741b342ec466f121480b5edded42e4b7ee850ce7a418ee AS builder

ARG TARGETARCH
ARG TARGETVARIANT
ARG EARNAPP_VERSION=""

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/opt/earnapp
ENV BIN_PATH=$APP_DIR/earnapp
ENV INSTALLER_URL=https://brightdata.com/static/earnapp/install.sh
ENV CDN_BASE=https://cdn-earnapp.b-cdn.net/static

# Minimal dependencies to download binary
RUN apt-get update && \
    apt-get install -y curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p $APP_DIR

# Fetch latest version if not specified
RUN if [ -z "$EARNAPP_VERSION" ]; then \
        export EARNAPP_VERSION=$(curl -fsSL $INSTALLER_URL | grep VERSION= | cut -d'"' -f2); \
    fi && \
    echo "[INFO] Installing EarnApp version $EARNAPP_VERSION for arch $TARGETARCH/$TARGETVARIANT" && \
    case "$TARGETARCH" in \
        amd64) FILE="earnapp-x64-$EARNAPP_VERSION" ;; \
        arm64) FILE="earnapp-aarch64-$EARNAPP_VERSION" ;; \
        arm) \
            case "$TARGETVARIANT" in \
                v7|v6) FILE="earnapp-arm7l-$EARNAPP_VERSION" ;; \
                *) echo "[ERROR] Unsupported ARM variant: $TARGETVARIANT"; exit 1 ;; \
            esac ;; \
        *) echo "[ERROR] Unsupported architecture: $TARGETARCH"; exit 1 ;; \
    esac && \
    curl -fL "$CDN_BASE/$FILE" -o "$BIN_PATH" && \
    chmod +x "$BIN_PATH" && \
    echo "[INFO] EarnApp binary downloaded."

# --------------------------
# Stage 2: Runtime
# --------------------------
FROM debian:bookworm-slim@sha256:56ff6d36d4eb3db13a741b342ec466f121480b5edded42e4b7ee850ce7a418ee

ENV APP_DIR=/opt/earnapp
ENV BIN_PATH=$APP_DIR/earnapp
ENV CONFIG_DIR=/etc/earnapp

# Minimal runtime dependencies
RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*

# Fake hostnamectl for EarnApp
RUN echo -e '#!/bin/sh\nhostname' > /usr/bin/hostnamectl && chmod +x /usr/bin/hostnamectl

# Fake lsb_release for EarnApp
RUN echo -e '#!/bin/sh\necho "Distributor ID: Debian"\necho "Description: Debian Bookworm"\necho "Release: 12"\necho "Codename: bookworm"' \
    > /usr/bin/lsb_release && chmod +x /usr/bin/lsb_release

# Create directories
RUN mkdir -p $APP_DIR $CONFIG_DIR

# Copy EarnApp binary from builder
COPY --from=builder $BIN_PATH $BIN_PATH
RUN chmod +x $BIN_PATH

WORKDIR $APP_DIR

# Copy entrypoint script
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Persistent configuration
VOLUME ["/etc/earnapp"]

# Entrypoint
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
