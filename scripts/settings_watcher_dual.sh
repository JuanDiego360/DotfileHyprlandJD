#!/usr/bin/env bash
# settings_watcher_dual.sh — Extiende settings_watcher.sh para emitir .lua además de .conf.
#
# Por qué: Hyprland 0.57+ elimina hyprlang. Mientras el sistema esté en 0.55/0.56,
# seguimos generando .conf como hace el watcher original. Cuando detect-config-target
# devuelva "lua", este script también compila los módulos Lua desde el mismo JSON,
# y un symlink determina cuál carga Hyprland.
#
# Uso:
#   settings_watcher_dual.sh                       # watcher (loop inotifywait)
#   settings_watcher_dual.sh --compile             # compila una vez y sale
#   settings_watcher_dual.sh --compile --target lua|conf  # fuerza un target
#
# Variables:
#   HYPRLAND_LUA_OUT_DIR  (default: ~/.config/hypr/lua)
#   HYPRLAND_DOTFILES     (default: ~/dotfiles)
#   SKIP_CONF=1           # no regenerar .conf (útil para test sólo Lua)

set -euo pipefail

HYPRLAND_DOTFILES="${HYPRLAND_DOTFILES:-$HOME/dotfiles}"
HYPRLAND_LUA_OUT_DIR="${HYPRLAND_LUA_OUT_DIR:-$HOME/.config/hypr/lua}"
TEMPLATES_DIR="$HYPRLAND_DOTFILES/templates"
COMPILE_LUA="$HYPRLAND_DOTFILES/scripts/compile_settings.lua"
DETECT="$HYPRLAND_DOTFILES/bin/detect-config-target.sh"

# Reutiliza el watcher original (sin forkear lógica)
ORIGINAL_WATCHER="$HOME/.config/hypr/scripts/settings_watcher.sh"

[[ -x "$DETECT" ]] || { echo "Falta $DETECT (chmod +x)"; exit 2; }
[[ -f "$COMPILE_LUA" ]] || { echo "Falta $COMPILE_LUA"; exit 2; }

SETTINGS_FILE="$HOME/.config/hypr/settings.json"
DEFAULT_FILE="$HOME/.config/hypr/default_settings.json"

compile_lua() {
    local target="${1:-auto}"
    if [[ "$target" == "auto" ]]; then
        target=$("$DETECT")
    fi
    [[ "$target" == "lua" ]] || { echo "compile_lua: target=$target, salto"; return 0; }

    mkdir -p "$HYPRLAND_LUA_OUT_DIR/config"
    echo "Compilando módulos Lua en $HYPRLAND_LUA_OUT_DIR..."
    if lua "$COMPILE_LUA" "$SETTINGS_FILE" "$DEFAULT_FILE" "$HYPRLAND_LUA_OUT_DIR" "$TEMPLATES_DIR"; then
        echo "Lua OK"
    else
        echo "Lua FALLÓ — no se aplicará reload" >&2
        return 1
    fi
}

compile_conf() {
    if [[ "${SKIP_CONF:-0}" == "1" ]]; then return 0; fi
    if [[ -x "$ORIGINAL_WATCHER" ]]; then
        bash "$ORIGINAL_WATCHER" --compile
    else
        echo "WARN: no encontré $ORIGINAL_WATCHER, sólo emito Lua" >&2
    fi
}

# Decide si hace reload Hyprland o sólo Quickshell
maybe_reload() {
    local target
    target=$("$DETECT")
    if [[ "$target" == "lua" ]]; then
        # En modo Lua, hyprland.conf -> require("config.*") o apuntar a hyprland.lua
        # Por seguridad: no reload automático en modo Lua la primera vez (revisar diff antes)
        if [[ "${HYPRLAND_LUA_AUTORELOAD:-0}" == "1" ]]; then
            hyprctl reload 2>/dev/null || true
        else
            echo "Lua emitido. HYPRLAND_LUA_AUTORELOAD=0 -> NO se aplicó hyprctl reload"
        fi
    fi
    # El modo conf ya hace su propio reload dentro del watcher original
}

# CLI
case "${1:-}" in
    --compile)
        shift
        target="auto"
        for arg in "$@"; do
            case "$arg" in
                --target=*) target="${arg#--target=}" ;;
            esac
        done
        compile_conf
        compile_lua "$target"
        maybe_reload
        exit 0
        ;;
esac

# Modo watcher
echo "settings_watcher_dual: watching $SETTINGS_FILE"
compile_conf
compile_lua auto
maybe_reload

inotifywait -m -q -e close_write,moved_to --format '%w%f' \
    "$(dirname "$SETTINGS_FILE")" \
    2>/dev/null | while read -r filepath; do
    if [[ "$filepath" == "$SETTINGS_FILE" ]]; then
        compile_conf
        compile_lua auto
        maybe_reload
    fi
done
