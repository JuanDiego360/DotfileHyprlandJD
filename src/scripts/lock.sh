#!/usr/bin/env bash

# Source and initialize quickshell dynamic caching
source "$(dirname "$(realpath "${BASH_SOURCE[0]}")")/caching.sh"
qs_ensure_cache "lock"

case "$1" in
    --static) action="activateStatic" ;;
    --reauth) action="restartAuth" ;;
    *) action="activate" ;;
esac

if ! pgrep -f "quickshell.*Shell.qml" >/dev/null; then
    quickshell -p "$MAIN_QML" >/dev/null 2>&1 &
    sleep 0.8
fi

quickshell -p "$MAIN_QML" ipc call lock "$action"
