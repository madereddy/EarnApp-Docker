# Base image
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV EARNAPP_HOME=/opt/earnapp
ENV CONFIG_DIR=/etc/earnapp

# --------------------------
# Install minimal dependencies
# --------------------------
RUN apt-get update && apt-get install -y \
    wget \
    curl \
    ca-certificates \
    libssl3 \
    libcurl4 \
    libcap2 \
    libstdc++6 \
    bash \
    && rm -rf /var/lib/apt/lists/*

# --------------------------
# Fake hostnamectl for EarnApp
# --------------------------
RUN echo -e '#!/bin/sh\nhostname' > /usr/bin/hostnamectl && chmod +x /usr/bin/hostnamectl

# --------------------------
# Fake lsb_release for EarnApp
# --------------------------
RUN echo -e '#!/bin/sh\necho "Distributor ID: Ubuntu"\necho "Description: Ubuntu 24.04"\necho "Release: 24.04"\necho "Codename: lunar"' \
    > /usr/bin/lsb_release && chmod +x /usr/bin/lsb_release

# --------------------------
# Create non-root user
# --------------------------
RUN useradd -m earnappuser

# --------------------------
# Create directories
# --------------------------
RUN mkdir -p $EARNAPP_HOME $CONFIG_DIR && chown -R earnappuser:earnappuser $EARNAPP_HOME $CONFIG_DIR

WORKDIR $EARNAPP_HOME

# --------------------------
# Copy entrypoint script
# --------------------------
COPY src/entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# --------------------------
# Volume for persistent configuration
# --------------------------
VOLUME ["/etc/earnapp"]

# --------------------------
# Entrypoint
# --------------------------
ENTRYPOINT ["/entrypoint.sh"]
CMD ["run"]
