#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# Config — sourced from Docker ENV, with safe fallbacks
# --------------------------
APP_DIR="${APP_DIR:-/app/src/}"
BIN_PATH="${BIN_PATH:-/usr/bin/earnapp}"
CONFIG_DIR="${CONFIG_DIR:-/etc/earnapp}"
INSTALLER_URL="${INSTALLER_URL:-https://brightdata.com/static/earnapp/install.sh}"
DEBUG_MODE="${DEBUG_MODE:-0}"
EARNAPP_VERSION="${EARNAPP_VERSION:-}"

# --------------------------
# Debug mode
# --------------------------
if [[ "$DEBUG_MODE" == "1" ]]; then
    echo "[INFO] DEBUG_MODE enabled."
    set -x
fi

# --------------------------
# Ensure directories exist
# --------------------------
mkdir -p "$APP_DIR" "$CONFIG_DIR"
touch "$CONFIG_DIR/status"

# --------------------------
# Install EarnApp at runtime via patched installer
# --------------------------
if [[ ! -x "$BIN_PATH" ]]; then
    echo "[INFO] EarnApp binary not found, installing..."

    # Unset _ to prevent the shell's last-command variable from being inherited
    unset _

    TMP_INSTALL="/tmp/earnapp.sh"
    curl -fsSL "$INSTALLER_URL" -o "$TMP_INSTALL" \
        || { echo "[ERROR] Failed to download EarnApp installer. Check your internet connection."; exit 1; }

    # Patch install.sh to pin version if EARNAPP_VERSION is defined
    if [[ -n "${EARNAPP_VERSION:-}" ]]; then
        echo "[INFO] Patching installer to install version $EARNAPP_VERSION..."
        sed -i "s/^VERSION=\"[^\"]*\"/VERSION=\"$EARNAPP_VERSION\"/" "$TMP_INSTALL"
    fi

    if [[ "$DEBUG_MODE" == "1" ]]; then
        echo "yes" | bash "$TMP_INSTALL" \
            || { echo "[ERROR] EarnApp installation failed."; exit 1; }
    else
        echo "yes" | bash "$TMP_INSTALL" &>/dev/null \
            || { echo "[ERROR] EarnApp installation failed."; exit 1; }
    fi

    rm -f "$TMP_INSTALL"
    echo "[INFO] EarnApp installed successfully."
fi

# --------------------------
# Validate binary
# --------------------------
if [[ ! -x "$BIN_PATH" ]]; then
    echo "[ERROR] EarnApp binary not found at $BIN_PATH after installation attempt."
    exit 1
fi

# --------------------------
# Wait for service file to be created by finish_install
# --------------------------
SERVICE_FILE="/etc/systemd/system/earnapp.service"
echo "[INFO] Waiting for EarnApp service file..."
WAIT=0
until [[ -f "$SERVICE_FILE" ]] || [[ $WAIT -ge 30 ]]; do
    sleep 1
    WAIT=$((WAIT + 1))
done

if [[ ! -f "$SERVICE_FILE" ]]; then
    echo "[ERROR] EarnApp service file not found after ${WAIT}s. Installation may have failed."
    exit 1
fi
echo "[INFO] Service file found after ${WAIT}s."

# --------------------------
# UUID handling
# --------------------------
if [[ -n "${EARNAPP_UUID:-}" ]]; then
    echo -n "$EARNAPP_UUID" > "$CONFIG_DIR/uuid"
    echo "[INFO] Using UUID from environment variable."
elif [[ ! -f "$CONFIG_DIR/uuid" ]]; then
    echo "[WARN] No UUID found. EarnApp will generate one automatically."
fi
chmod 600 "$CONFIG_DIR/"* 2>/dev/null || true

# --------------------------
# Warn if /etc/earnapp is not a volume mount
# --------------------------
if ! grep -q " $CONFIG_DIR " /proc/mounts 2>/dev/null; then
    echo "############################################################"
    echo "[WARN] /etc/earnapp is NOT mounted as a volume!"
    echo "[WARN] Your UUID will be lost every time this container restarts."
    echo "[WARN] You will need to re-register this device on each restart."
    echo "[WARN] To persist your UUID, mount a volume:"
    echo "[WARN]   docker run -v /path/to/earnapp:/etc/earnapp ..."
    echo "############################################################"
    if [[ -z "${EARNAPP_UUID:-}" ]]; then
        rm -f "$CONFIG_DIR/uuid"
    fi
fi

# --------------------------
# Start EarnApp via systemctl
# --------------------------
echo "[INFO] Starting EarnApp via systemctl..."
systemctl start earnapp 2>/dev/null || true
sleep 2

# --------------------------
# Wait for UUID registration with exponential backoff
# --------------------------
DEVICE_ID="unknown"
MAX_ATTEMPTS=5
BACKOFF=2
MAX_BACKOFF=30

for i in $(seq 1 $MAX_ATTEMPTS); do
    DEVICE_ID=$(("$BIN_PATH" showid 2>/dev/null || true) | tr -d '[:space:]')
    if [[ -n "$DEVICE_ID" && "$DEVICE_ID" != "undefined" ]]; then
        break
    fi
    echo "[INFO] Waiting for EarnApp registration (attempt $i/$MAX_ATTEMPTS, retrying in ${BACKOFF}s)..."
    sleep "$BACKOFF"
    BACKOFF=$((BACKOFF * 2))
    [[ $BACKOFF -gt $MAX_BACKOFF ]] && BACKOFF=$MAX_BACKOFF
done

# Fallback to uuid file if showid still not ready
if [[ "$DEVICE_ID" == "unknown" || "$DEVICE_ID" == "undefined" ]]; then
    DEVICE_ID=$(cat "$CONFIG_DIR/uuid" 2>/dev/null | tr -d '[:space:]' || echo "unknown")
fi

# --------------------------
# Verify uuid and registered file match
# Only check when EarnApp manages the UUID itself (no env var override)
# --------------------------
if [[ -z "${EARNAPP_UUID:-}" && -f "$CONFIG_DIR/registered" ]]; then
    REGISTERED_ID=$(tr -d '[:space:]' < "$CONFIG_DIR/registered" 2>/dev/null || echo "")
    if [[ -n "$REGISTERED_ID" && "$REGISTERED_ID" != "$DEVICE_ID" ]]; then
        echo "[WARN] UUID mismatch detected:"
        echo "[WARN]   uuid file:        $DEVICE_ID"
        echo "[WARN]   registered file:  $REGISTERED_ID"
    fi
fi

# --------------------------
# Print registration info
# --------------------------
echo "------------------------------------------------------------"
if [[ "$DEVICE_ID" == "unknown" ]]; then
    echo "[WARN] UUID not yet available. EarnApp may still be registering in the background."
    echo "[INFO] This is normal on first run or slow networks."
    echo "[INFO] Once ready, run: docker exec earnapp earnapp showid"
    echo "[INFO] Then visit:      https://earnapp.com/r/<your-device-id>"
elif [[ ! "$DEVICE_ID" =~ ^sdk-node-[a-f0-9]{32}$ ]]; then
    echo "[WARN] Device ID format looks unexpected: $DEVICE_ID"
    echo "[INFO] Device ID: $DEVICE_ID"
    echo "[INFO] If not yet registered, visit: https://earnapp.com/r/$DEVICE_ID"
else
    echo "[INFO] Device ID: $DEVICE_ID"
    echo "[INFO] If not yet registered, visit: https://earnapp.com/r/$DEVICE_ID"
fi
echo "------------------------------------------------------------"

# --------------------------
# Run EarnApp loop
# --------------------------
BACKOFF=5
MAX_BACKOFF=300

while true; do
    START_TIME=$(date +%s)
    "$BIN_PATH" run || true
    RUN_DURATION=$(( $(date +%s) - START_TIME ))

    if [[ $RUN_DURATION -gt 60 ]]; then
        BACKOFF=5
        echo "[INFO] EarnApp exited after ${RUN_DURATION}s, restarting in ${BACKOFF}s..."
    else
        echo "[WARN] EarnApp crashed after ${RUN_DURATION}s, backing off ${BACKOFF}s..."
        sleep "$BACKOFF"
        BACKOFF=$((BACKOFF * 2))
        [[ $BACKOFF -gt $MAX_BACKOFF ]] && BACKOFF=$MAX_BACKOFF
    fi
done
