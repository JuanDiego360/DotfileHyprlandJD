#!/usr/bin/env bash
# switch-config-target.sh — Apunta el entry point de Hyprland al target correcto.
#
# En modo conf:  ~/.config/hypr/hyprland.conf  (fuente de verdad actual)
# En modo lua:   ~/.config/hypr/hyprland.lua   (require chain de los módulos)
#
# Si ya hay un entry point del target contrario, lo renombra a .bak.<target> por seguridad.

set -euo pipefail

HYPR_CFG_DIR="${HYPR_CFG_DIR:-$HOME/.config/hypr}"
DETECT="${DETECT:-$HOME/dotfiles/bin/detect-config-target.sh}"

target=$("$DETECT" 2>/dev/null || echo unavailable)
case "$target" in
    conf|lua) ;;
    unavailable)
        echo "No pude determinar la versión. Aborta." >&2; exit 2 ;;
    *) echo "Target desconocido: $target" >&2; exit 2 ;;
esac

cd "$HYPR_CFG_DIR"

stamp() { date +%Y%m%d-%H%M%S; }

# Backup cualquier entry point del otro target
if [[ "$target" == "lua" && -f hyprland.conf && ! -L hyprland.conf ]]; then
    cp -p hyprland.conf "hyprland.conf.bak.conf-$(stamp)"
    echo "Backup: hyprland.conf.bak.conf-$(stamp)"
fi
if [[ "$target" == "conf" && -f hyprland.lua && ! -L hyprland.lua ]]; then
    cp -p hyprland.lua "hyprland.lua.bak.lua-$(stamp)"
    echo "Backup: hyprland.lua.bak.lua-$(stamp)"
fi

case "$target" in
    lua)
        if [[ ! -f hyprland.lua ]]; then
            echo "No existe hyprland.lua. ¿Corriste settings_watcher_dual.sh --compile?" >&2
            exit 3
        fi
        # El binario de Hyprland carga hyprland.lua automáticamente si existe y no hay .conf,
        # o si hyprland.conf hace source. Aquí sólo informamos.
        echo "Target = lua. Hyprland cargará hyprland.lua si hyprland.conf está vacío o ausente."
        echo "Recomendación: deja hyprland.conf con UNA línea: source = ~/.config/hypr/lua/hyprland.lua"
        ;;
    conf)
        if [[ ! -f hyprland.conf ]]; then
            echo "No existe hyprland.conf" >&2; exit 3
        fi
        echo "Target = conf. Hyprland carga hyprland.conf."
        ;;
esac

echo "switch-config-target: target activo = $target"
