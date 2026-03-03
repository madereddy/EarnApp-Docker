#!/usr/bin/env bash
set -euo pipefail

# --------------------------
# Config — sourced from Docker ENV, with safe fallbacks
# --------------------------
APP_DIR="${APP_DIR:-/app/src/}"
BIN_PATH="${BIN_PATH:-/usr/bin/earnapp}"
CONFIG_DIR="${CONFIG_DIR:-/etc/earnapp}"

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
# Validate binary
# --------------------------
if [[ ! -x "$BIN_PATH" ]]; then
    echo "[ERROR] EarnApp binary not found at $BIN_PATH. Image may be corrupted."
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
# Start EarnApp with auto-restart loop
# --------------------------
echo "[INFO] Starting EarnApp..."
"$BIN_PATH" stop 2>/dev/null || true
sleep 1

backoff=5
MAX_BACKOFF=300

while true; do
    "$BIN_PATH" start 2>/dev/null || true
    sleep 2

    start_time=$(date +%s)
    "$BIN_PATH" run || true
    run_duration=$(( $(date +%s) - start_time ))

    if [[ $run_duration -gt 60 ]]; then
        backoff=5
        echo "[INFO] EarnApp exited after ${run_duration}s, restarting in ${backoff}s..."
    else
        echo "[WARN] EarnApp crashed after ${run_duration}s, backing off ${backoff}s before restart..."
        sleep "$backoff"
        backoff=$((backoff * 2))
        [[ $backoff -gt $MAX_BACKOFF ]] && backoff=$MAX_BACKOFF
    fi

    "$BIN_PATH" stop 2>/dev/null || true
    sleep 1
done
