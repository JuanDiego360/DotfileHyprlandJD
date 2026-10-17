#!/usr/bin/env bash

APP_ID="com.gabm.sattyfreeze"
RUNTIME_DIR="${XDG_RUNTIME_DIR:-/tmp}"
LOCK_FILE="${RUNTIME_DIR}/screen_draw.lock"
STATE_FILE="${RUNTIME_DIR}/screen_draw_last_action"

# Prevent concurrent executions with a non-blocking lock
exec 200>"$LOCK_FILE"
if ! flock -n 200; then
    exit 0
fi

# Debounce / cooldown: Ignore triggers within 600ms to prevent double-launches
NOW=$(date +%s%3N)
if [ -f "$STATE_FILE" ]; then
    LAST_TIME=$(cat "$STATE_FILE" 2>/dev/null || echo 0)
    DIFF=$((NOW - LAST_TIME))
    if [ "$DIFF" -ge 0 ] && [ "$DIFF" -lt 600 ]; then
        exit 0
    fi
fi
echo "$NOW" > "$STATE_FILE"

# TOGGLE OFF: If an annotation session is already active, kill it and exit
if pgrep -f "satty.*${APP_ID}" >/dev/null; then
    pkill -f "satty.*${APP_ID}" 2>/dev/null
    for i in {1..10}; do
        if ! pgrep -f "satty.*${APP_ID}" >/dev/null; then break; fi
        sleep 0.05
    done
    date +%s%3N > "$STATE_FILE"
    flock -u 200
    exit 0
fi

# TOGGLE ON: Detect focused monitor
FOCUSED_MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused) | .name' 2>/dev/null)
if [ -z "$FOCUSED_MONITOR" ]; then
    FOCUSED_MONITOR=$(hyprctl monitors -j 2>/dev/null | jq -r '.[0].name' 2>/dev/null)
fi

export GSK_RENDERER=gl

# Release the lock right before entering Satty so future toggle-off invocations can run
flock -u 200

# Freeze screen and launch interactive canvas in fullscreen
grim -o "$FOCUSED_MONITOR" - | satty \
    --filename - \
    --fullscreen current-screen \
    --no-window-decoration \
    --initial-tool brush \
    --disable-notifications \
    --app-id "$APP_ID" \
    --title "screen-freeze-annotate" \
    --brush-smooth-history-size 3
