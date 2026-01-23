#!/usr/bin/env bash
set -euo pipefail

INSTALLER_URL="https://brightdata.com/static/earnapp/install.sh"
CDN_BASE="https://cdn-earnapp.b-cdn.net/static"

APP_DIR="/opt/earnapp"
BIN_PATH="$APP_DIR/earnapp"
CONFIG_DIR="/etc/earnapp"

# ---- Validation ----
if [[ -z "${EARNAPP_UUID:-}" ]]; then
  echo "ERROR: EARNAPP_UUID is not set"
  exit 1
fi

mkdir -p "$APP_DIR" "$CONFIG_DIR"

# ---- Determine version ----
echo "Fetching EarnApp version info..."
curl -fsSL "$INSTALLER_URL" -o /tmp/earnapp_install.sh

VERSION=$(grep -E '^VERSION=' /tmp/earnapp_install.sh | cut -d'"' -f2)

if [[ -z "$VERSION" ]]; then
  echo "ERROR: Unable to determine EarnApp version"
  exit 1
fi

echo "EarnApp version: $VERSION"

# ---- Architecture detection ----
ARCH=$(uname -m)
PRODUCT="earnapp"

case "$ARCH" in
  x86_64|amd64)
    FILE="$PRODUCT-x64-$VERSION"
    ;;
  armv6l|armv7l)
    FILE="$PRODUCT-arm7l-$VERSION"
    ;;
  aarch64|arm64)
    FILE="$PRODUCT-aarch64-$VERSION"
    ;;
  *)
    echo "ERROR: Unsupported architecture: $ARCH"
    exit 1
    ;;
esac

# ---- Download binary ----
DOWNLOAD_URL="$CDN_BASE/$FILE"
echo "Downloading EarnApp binary ($ARCH)..."

curl -fL "$DOWNLOAD_URL" -o "$BIN_PATH"
chmod +x "$BIN_PATH"

# ---- Validate binary ----
if ! file "$BIN_PATH" | grep -qi executable; then
  echo "ERROR: Downloaded file is not a valid executable"
  exit 1
fi

# ---- Configure ----
echo "Configuring EarnApp..."
echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
touch "$CONFIG_DIR/status"
chmod 600 "$CONFIG_DIR/"*

# ---- Run ----
echo "Starting EarnApp..."
exec "$BIN_PATH" run