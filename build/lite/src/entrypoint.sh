#!/usr/bin/env bash
set -euo pipefail

# ---- Config ----
INSTALLER_URL="https://brightdata.com/static/earnapp/install.sh"
CDN_BASE="https://cdn-earnapp.b-cdn.net/static"
APP_DIR="/opt/earnapp"
BIN_PATH="$APP_DIR/earnapp"
CONFIG_DIR="/etc/earnapp"
RETRY_DELAY=5   # seconds between retries for binary or crashes
MAX_DOWNLOAD_RETRIES=5

# ---- Validation ----
if [[ -z "${EARNAPP_UUID:-}" ]]; then
  echo "ERROR: EARNAPP_UUID environment variable is not set!"
  echo "Set it via '-e EARNAPP_UUID=your-uuid' when running the container"
  exit 1
fi

mkdir -p "$APP_DIR" "$CONFIG_DIR"

# ---- Fetch EarnApp version ----
echo "[INFO] Fetching EarnApp version info..."
curl_opts="-fsSL"
version_attempts=0
while [[ $version_attempts -lt $MAX_DOWNLOAD_RETRIES ]]; do
    if curl $curl_opts "$INSTALLER_URL" -o /tmp/earnapp_install.sh; then
        VERSION=$(grep -E '^VERSION=' /tmp/earnapp_install.sh | cut -d'"' -f2)
        if [[ -n "$VERSION" ]]; then
            echo "[INFO] Detected EarnApp version: $VERSION"
            break
        fi
    fi
    version_attempts=$((version_attempts + 1))
    echo "[WARN] Failed to fetch version info. Retry $version_attempts/$MAX_DOWNLOAD_RETRIES in $RETRY_DELAY s..."
    sleep $RETRY_DELAY
done

if [[ -z "$VERSION" ]]; then
    echo "[ERROR] Could not determine EarnApp version after $MAX_DOWNLOAD_RETRIES attempts."
    exit 1
fi

# ---- Determine architecture ----
ARCH=$(uname -m)
PRODUCT="earnapp"
case "$ARCH" in
    x86_64|amd64) FILE="$PRODUCT-x64-$VERSION" ;;
    armv6l|armv7l) FILE="$PRODUCT-arm7l-$VERSION" ;;
    aarch64|arm64) FILE="$PRODUCT-aarch64-$VERSION" ;;
    *)
        echo "[ERROR] Unsupported architecture: $ARCH"
        exit 1
        ;;
esac

# ---- Download binary ----
DOWNLOAD_URL="$CDN_BASE/$FILE"
echo "[INFO] Downloading EarnApp binary for $ARCH from $DOWNLOAD_URL..."

download_attempts=0
while [[ $download_attempts -lt $MAX_DOWNLOAD_RETRIES ]]; do
    if curl -fL "$DOWNLOAD_URL" -o "$BIN_PATH"; then
        chmod +x "$BIN_PATH"
        echo "[INFO] EarnApp binary downloaded and marked executable."
        break
    fi
    download_attempts=$((download_attempts + 1))
    echo "[WARN] Download failed. Retry $download_attempts/$MAX_DOWNLOAD_RETRIES in $RETRY_DELAY s..."
    sleep $RETRY_DELAY
done

if [[ ! -x "$BIN_PATH" ]]; then
    echo "[ERROR] Could not download or make EarnApp binary executable."
    exit 1
fi

# ---- Configure EarnApp ----
echo "[INFO] Writing EARNAPP_UUID and initializing config..."
echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
touch "$CONFIG_DIR/status"
chmod 600 "$CONFIG_DIR/"*

# ---- Run EarnApp in loop with crash handling ----
echo "[INFO] Starting EarnApp. Will retry if it crashes..."
while true; do
    echo "[INFO] Executing EarnApp..."
    exec "$BIN_PATH" run || {
        echo "[WARN] EarnApp crashed. Retrying in $RETRY_DELAY seconds..."
        sleep $RETRY_DELAY
    }
done
