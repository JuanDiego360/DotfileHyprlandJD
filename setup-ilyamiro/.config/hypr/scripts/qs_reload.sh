#!/usr/bin/env bash
# Safe Quickshell reload that actually picks up QML file changes.
#
# Why: hyprctl reload does NOT re-execute exec-once directives, so the
# Quickshell process started at Hyprland launch keeps running with the
# QML it loaded at startup. To pick up changes to *.qml files (including
# the appLauncher popup that is only compiled on first use) we must
# explicitly kill and relaunch Quickshell.
#
# Usage: qs_reload.sh
#        qs_reload.sh logs   # tail the relaunch log

set -e

SHELL_QML="$HOME/.config/hypr/scripts/quickshell/Shell.qml"
LOG=/tmp/quickshell_relaunch.log
: > "$LOG"

if [[ "${1:-}" == "logs" ]]; then
    tail -n 50 "$LOG" 2>/dev/null || echo "(no log yet)"
    exit 0
fi

# Find current Quickshell PID (the one bound to Shell.qml)
QS_PID=$(pgrep -f "quickshell -p.*Shell.qml" | head -1 || true)
if [[ -n "$QS_PID" ]]; then
    echo "[qs_reload] killing quickshell PID=$QS_PID" | tee -a "$LOG"
    kill "$QS_PID" 2>/dev/null || true
    # Give it a moment to die cleanly
    for _ in 1 2 3 4 5; do
        if ! kill -0 "$QS_PID" 2>/dev/null; then
            break
        fi
        sleep 0.2
    done
    # If still alive, send a stronger signal (without -9 if possible)
    if kill -0 "$QS_PID" 2>/dev/null; then
        echo "[qs_reload] SIGTERM didn't work, escalating" | tee -a "$LOG"
        kill -9 "$QS_PID" 2>/dev/null || true
    fi
else
    echo "[qs_reload] no quickshell process found, starting fresh" | tee -a "$LOG"
fi

# Relaunch in background
echo "[qs_reload] starting quickshell" | tee -a "$LOG"
nohup quickshell -p "$SHELL_QML" >>"$LOG" 2>&1 &
disown
echo "[qs_reload] done (PID=$!)" | tee -a "$LOG"
