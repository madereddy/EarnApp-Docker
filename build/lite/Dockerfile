# --------------------------
# Stage 1: Build stage
# --------------------------
FROM ubuntu:24.04-minimal AS builder

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/opt/earnapp
ENV BIN_PATH=$APP_DIR/earnapp

# Install curl only in build stage
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

WORKDIR $APP_DIR

# Download EarnApp binary
ARG EARNAPP_UUID
ENV EARNAPP_UUID=${EARNAPP_UUID:-dummy}

RUN ARCH=$(uname -m) && \
    VERSION=$(curl -fsSL https://brightdata.com/static/earnapp/install.sh | grep VERSION= | cut -d'"' -f2) && \
    PRODUCT="earnapp" && \
    case "$ARCH" in \
        x86_64|amd64) FILE="$PRODUCT-x64-$VERSION" ;; \
        armv6l|armv7l) FILE="$PRODUCT-arm7l-$VERSION" ;; \
        aarch64|arm64) FILE="$PRODUCT-aarch64-$VERSION" ;; \
        *) echo "[ERROR] Unsupported arch: $ARCH"; exit 1 ;; \
    esac && \
    curl -fL "https://cdn-earnapp.b-cdn.net/static/$FILE" -o "$BIN_PATH" && \
    chmod +x "$BIN_PATH"

# --------------------------
# Stage 2: Final runtime
# --------------------------
FROM ubuntu:24.04-minimal

ENV DEBIAN_FRONTEND=noninteractive
ENV APP_DIR=/opt/earnapp
ENV BIN_PATH=$APP_DIR/earnapp
ENV CONFIG_DIR=/etc/earnapp

# Minimal runtime packages
RUN apt-get update && \
    apt-get install -y curl && \
    rm -rf /var/lib/apt/lists/*

# Fake hostnamectl
RUN echo -e '#!/bin/sh\nhostname' > /usr/bin/hostnamectl && chmod +x /usr/bin/hostnamectl

# Fake lsb_release
RUN echo -e '#!/bin/sh\necho "Distributor ID: Ubuntu"\necho "Description: Ubuntu 24.04"\necho "Release: 24.04"\necho "Codename: lunar"' \
    > /usr/bin/lsb_release && chmod +x /usr/bin/lsb_release

# Create directories
RUN mkdir -p $APP_DIR $CONFIG_DIR

# Copy binary from builder
COPY --from=builder $BIN_PATH $BIN_PATH
RUN chmod +x $BIN_PATH

WORKDIR $APP_DIR

# Copy entrypoint
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Volume for persistent config
VOLUME ["/etc/earnapp"]

ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]