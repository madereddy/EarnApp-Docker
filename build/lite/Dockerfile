FROM ubuntu:24.04@sha256:cd1dba651b3080c3686ecf4e3c4220f026b521fb76978881737d24f200828b2b

ENV DEBIAN_FRONTEND=noninteractive
ENV container=docker

# Install required runtime dependencies
RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    file \
    procps \
 && rm -rf /var/lib/apt/lists/*

# Create directories
RUN mkdir -p /opt/earnapp /etc/earnapp

# Copy unified entrypoint script
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

# Persist EarnApp config
VOLUME ["/etc/earnapp"]

# Healthcheck: container is healthy if earnapp is running
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD pgrep earnapp > /dev/null || exit 1

# Run as PID 1
ENTRYPOINT ["/entrypoint.sh"]