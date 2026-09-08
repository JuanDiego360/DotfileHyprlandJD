#!/usr/bin/env bash

detect_install_state() {
    local LEGACY_MARKER="$HOME/.local/state/imperative-dots-version"
    local LEGACY_WATCHER="$HOME/.config/hypr/scripts/settings_watcher.sh"
    local LEGACY_JSON="$HOME/.config/hypr/settings.json"
    local NEW_MARKER="$HOME/.local/state/serpantinum/version"

    if [[ -f "$NEW_MARKER" ]]; then
        echo "current"
    elif [[ -f "$LEGACY_MARKER" || -f "$LEGACY_WATCHER" || -f "$LEGACY_JSON" ]]; then
        echo "legacy"
    else
        echo "fresh"
    fi
}
