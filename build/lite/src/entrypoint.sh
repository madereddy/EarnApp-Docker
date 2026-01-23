#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# Config
# --------------------------
INSTALLER_URL="https://brightdata.com/static/earnapp/install.sh"
CDN_BASE="https://cdn-earnapp.b-cdn.net/static"
APP_DIR="/opt/earnapp"
BIN_PATH="$APP_DIR/earnapp"
CONFIG_DIR="/etc/earnapp"

# --------------------------
# Debug mode
# --------------------------
if [[ "${DEBUG_MODE:-}" == "1" ]]; then
    echo "[INFO] DEBUG_MODE enabled, launching shell..."
    exec bash
fi

# --------------------------
# Validate UUID
# --------------------------
if [[ -z "${EARNAPP_UUID:-}" ]]; then
    echo "[ERROR] EARNAPP_UUID not set!"
    exit 1
fi

# --------------------------
# Prepare directories and config files
# --------------------------
mkdir -p "$APP_DIR" "$CONFIG_DIR"
echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
touch "$CONFIG_DIR/status"
chmod 600 "$CONFIG_DIR/"*

# --------------------------
# Download EarnApp if missing
# --------------------------
if [[ ! -x "$BIN_PATH" ]]; then
    echo "[INFO] Downloading EarnApp..."
    ARCH=$(uname -m)
    VERSION=$(curl -fsSL "$INSTALLER_URL" | grep VERSION= | cut -d'"' -f2)
    PRODUCT="earnapp"
    case "$ARCH" in
        x86_64|amd64) FILE="$PRODUCT-x64-$VERSION" ;;
        armv6l|armv7l) FILE="$PRODUCT-arm7l-$VERSION" ;;
        aarch64|arm64) FILE="$PRODUCT-aarch64-$VERSION" ;;
        *) echo "[ERROR] Unsupported architecture: $ARCH"; exit 1 ;;
    esac
    curl -fL "$CDN_BASE/$FILE" -o "$BIN_PATH"
    chmod +x "$BIN_PATH"
    echo "[INFO] EarnApp downloaded."
fi

# --------------------------
# Start EarnApp in background
# --------------------------
echo "[INFO] Starting EarnApp..."
"$BIN_PATH" start

# --------------------------
# Keep container alive
# --------------------------
echo "[INFO] EarnApp started. Container will remain running..."
tail -f /dev/null
