#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# Config — sourced from Docker ENV, with safe fallbacks
# --------------------------
APP_DIR="${APP_DIR:-/app/src/}"
BIN_PATH="${BIN_PATH:-/usr/bin/earnapp}"
CONFIG_DIR="${CONFIG_DIR:-/etc/earnapp}"
INSTALLER_URL="${INSTALLER_URL:-https://brightdata.com/static/earnapp/install.sh}"
CDN_BASE="${CDN_BASE:-https://cdn-earnapp.b-cdn.net/static}"
EARNAPP_VERSION="${EARNAPP_VERSION:-}"  # optional pinned version

# --------------------------
# Debug mode
# --------------------------
if [[ "${DEBUG_MODE:-}" == "1" ]]; then
    echo "[INFO] DEBUG_MODE enabled, launching shell..."
    exec bash
fi

# --------------------------
# Ensure directories exist
# --------------------------
mkdir -p "$APP_DIR" "$CONFIG_DIR"
touch "$CONFIG_DIR/status"

# --------------------------
# Install EarnApp if binary missing
# --------------------------
if [[ ! -x "$BIN_PATH" ]]; then
    echo "[INFO] EarnApp binary not found, installing..."

    if [[ -n "$EARNAPP_VERSION" ]]; then
        echo "[INFO] Installing pinned version: $EARNAPP_VERSION"
        ARCH=$(uname -m)
        case "$ARCH" in
            x86_64) FILE="earnapp-x64-$EARNAPP_VERSION" ;;
            aarch64) FILE="earnapp-aarch64-$EARNAPP_VERSION" ;;
            armv7l) FILE="earnapp-arm7l-$EARNAPP_VERSION" ;;
            *) echo "[ERROR] Unsupported architecture: $ARCH"; exit 1 ;;
        esac
        curl -fsSL "$CDN_BASE/$FILE" -o "$BIN_PATH" \
            || { echo "[ERROR] Failed to download EarnApp $EARNAPP_VERSION"; exit 1; }
        chmod +x "$BIN_PATH"
    else
        echo "[INFO] No EARNAPP_VERSION set, installing latest version..."
        curl -fsSL "$INSTALLER_URL" -o /tmp/earnapp.sh \
            || { echo "[ERROR] Failed to download installer"; exit 1; }
        echo "yes" | bash /tmp/earnapp.sh || { echo "[ERROR] Installer failed"; exit 1; }
        rm -f /tmp/earnapp.sh
    fi

    echo "[INFO] EarnApp installed successfully."
fi

# --------------------------
# UUID handling
# --------------------------
UUID_SOURCE="unknown"
if [[ -z "${EARNAPP_UUID:-}" ]]; then
    echo "[WARN] EARNAPP_UUID not set — UUID will be generated."
    if [[ -f "$CONFIG_DIR/uuid" ]]; then
        UUID_SOURCE="volume"
    else
        UUID_SOURCE="generated"
    fi
else
    echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
    UUID_SOURCE="env"
fi
chmod 600 "$CONFIG_DIR/"*

# --------------------------
# Warn if /etc/earnapp not mounted as volume
# --------------------------
if ! grep -q " $CONFIG_DIR " /proc/mounts 2>/dev/null; then
    echo "############################################################"
    echo "[WARN] /etc/earnapp is NOT mounted as a volume!"
    echo "[WARN] Your UUID may be lost on container restart."
    if [[ -z "${EARNAPP_UUID:-}" ]]; then
        rm -f "$CONFIG_DIR/uuid"
    fi
    echo "############################################################"
fi

# --------------------------
# Start EarnApp early for UUID generation
# --------------------------
echo "[INFO] Starting EarnApp..."
"$BIN_PATH" stop 2>/dev/null || true
sleep 1
"$BIN_PATH" start 2>/dev/null || true
sleep 2

# --------------------------
# Wait for UUID registration (with backoff)
# --------------------------
echo ""
echo "------------------------------------------------------------"
DEVICE_ID="unknown"
if [[ -n "${EARNAPP_UUID:-}" ]]; then
    DEVICE_ID=$(echo -n "$EARNAPP_UUID" | tr -d '[:space:]')
else
    uuid_backoff=2
    uuid_max_backoff=30
    MAX_ATTEMPTS=5
    for i in $(seq 1 $MAX_ATTEMPTS); do
        DEVICE_ID=$(("$BIN_PATH" showid 2>/dev/null || true) | tr -d '[:space:]')
        if [[ -n "$DEVICE_ID" && "$DEVICE_ID" != "undefined" ]]; then
            break
        fi
        echo "[INFO] Waiting for EarnApp to register... (attempt $i/$MAX_ATTEMPTS, retry ${uuid_backoff}s)"
        "$BIN_PATH" stop 2>/dev/null || true
        sleep 1
        "$BIN_PATH" start 2>/dev/null || true
        sleep "$uuid_backoff"
        uuid_backoff=$((uuid_backoff * 2))
        [[ $uuid_backoff -gt $uuid_max_backoff ]] && uuid_backoff=$uuid_max_backoff
    done

    if [[ "$DEVICE_ID" == "unknown" || "$DEVICE_ID" == "undefined" ]]; then
        DEVICE_ID=$(cat "$CONFIG_DIR/uuid" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
    fi
fi

# --------------------------
# Show registration info
# --------------------------
if [[ "$DEVICE_ID" == "unknown" ]]; then
    echo "[WARN] UUID not available yet — registration may still be in progress."
    echo "[INFO] Check: docker exec <container> earnapp showid"
    echo "[INFO] Visit: https://earnapp.com/r/<your-device-id>"
else
    echo "[INFO] Device ID: $DEVICE_ID"
    case "$UUID_SOURCE" in
        env) echo "[INFO] UUID source: environment variable" ;;
        volume) echo "[INFO] UUID source: existing volume" ;;
        generated) echo "[INFO] UUID source: auto-generated" ;;
    esac
    echo "[INFO] Registration link: https://earnapp.com/r/$DEVICE_ID"
fi
echo "------------------------------------------------------------"
echo ""

# --------------------------
# Main loop — auto-restart EarnApp
# --------------------------
backoff=5
MAX_BACKOFF=300

while true; do
    start_time=$(date +%s)
    "$BIN_PATH" run || true
    run_duration=$(( $(date +%s) - start_time ))

    if [[ $run_duration -gt 60 ]]; then
        backoff=5
        echo "[INFO] EarnApp exited after ${run_duration}s, restarting in ${backoff}s..."
    else
        echo "[WARN] EarnApp crashed after ${run_duration}s, backing off ${backoff}s..."
        sleep "$backoff"
        backoff=$((backoff * 2))
        [[ $backoff -gt $MAX_BACKOFF ]] && backoff=$MAX_BACKOFF
    fi

    "$BIN_PATH" stop 2>/dev/null || true
    sleep 1
    "$BIN_PATH" start 2>/dev/null || true
    sleep 2
done
