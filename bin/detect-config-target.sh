#!/usr/bin/env bash
# detect-config-target.sh — Decide si Hyprland debe cargar .conf o .lua.
#
# Salida: imprime en stdout una de tres líneas:
#   conf       → 0.55 o 0.56.x, o hyprlang forzado
#   lua        → 0.57+ o LUA_FORCE=1
#   unavailable→ no se puede determinar (sin hyprctl ni pacman, sin override)
#
# Variables de entorno reconocidas:
#   HYPRLAND_CONFIG_TARGET=conf|lua   override explícito (sticky)
#   HYPRLAND_LUA_FORCE=1              alias moderno del override
#   HYPRLAND_VERSION_CACHE=/ruta      cache de versión (opcional)
#
# No modifica nada en disco. Llamar antes de aplicar cambios.

set -u

CACHE="${HYPRLAND_VERSION_CACHE:-$HOME/.cache/hyprland-target}"

emit() { printf '%s\n' "$1"; }

# 1. Override sticky (gana siempre)
if [[ -n "${HYPRLAND_CONFIG_TARGET:-}" ]]; then
    case "$HYPRLAND_CONFIG_TARGET" in
        conf|lua) emit "$HYPRLAND_CONFIG_TARGET"; exit 0 ;;
        *)        echo "detect-config-target: HYPRLAND_CONFIG_TARGET inválido: $HYPRLAND_CONFIG_TARGET" >&2; exit 2 ;;
    esac
fi
if [[ "${HYPRLAND_LUA_FORCE:-0}" == "1" ]]; then
    emit lua; exit 0
fi

# 2. Versión en vivo vía hyprctl (más fiable: refleja el binario cargado)
VERSION=""
if command -v hyprctl >/dev/null 2>&1; then
    VERSION=$(hyprctl version 2>/dev/null \
        | head -n1 \
        | sed -E 's/.*Hyprland[, ]+v?([0-9]+)\.([0-9]+).*/\1.\2/')
fi

# 3. Fallback: pacman (CachyOS / Arch) si hyprctl falló
if [[ -z "$VERSION" ]] && command -v pacman >/dev/null 2>&1; then
    PKG=$(pacman -Q hyprland 2>/dev/null | awk '{print $2}')
    if [[ "$PKG" =~ ([0-9]+)\.([0-9]+) ]]; then
        VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
fi

# 4. Fallback: nix (caso del upstream ilyamiro)
if [[ -z "$VERSION" ]] && command -v nix >/dev/null 2>&1; then
    NIX_PKG=$(nix-env --query --attr hyprland --raw 2>/dev/null || true)
    if [[ "$NIX_PKG" =~ ([0-9]+)\.([0-9]+) ]]; then
        VERSION="${BASH_REMATCH[1]}.${BASH_REMATCH[2]}"
    fi
fi

if [[ -z "$VERSION" ]]; then
    emit unavailable
    exit 0
fi

# Persistir cache (para que spawns sin sesión Wayland funcionen)
mkdir -p "$(dirname "$CACHE")" 2>/dev/null && echo "$VERSION" > "$CACHE" 2>/dev/null || true

# 5. Decisión. Punto de corte: 0.57 rompe hyprlang.
MAJOR="${VERSION%%.*}"
MINOR="${VERSION#*.}"
if (( MAJOR > 0 )) || (( MAJOR == 0 && MINOR >= 57 )); then
    emit lua
else
    emit conf
fi
