#!/bin/bash
# Toggle modo juego: activa/desactiva el bloqueo de mouse al monitor del juego
# Creando/borrando /tmp/game-mode-lock.state y recargando Hyprland

STATE_FILE="/tmp/game-mode-lock.state"

if [ -f "$STATE_FILE" ]; then
    rm -f "$STATE_FILE"
    hyprctl reload 2>&1
    sleep 1
    killall -q -9 qs
    sleep 1
    qs -c ii &
    notify-send "🎮 Modo JUEGO: DESACTIVADO" "Mouse libre — podés usar otras apps" -a "Hyprland"
else
    touch "$STATE_FILE"
    hyprctl reload 2>&1
    sleep 1
    killall -q -9 qs
    sleep 1
    qs -c ii &
    notify-send "🎮 Modo JUEGO: ACTIVADO" "Mouse bloqueado al monitor del juego" -a "Hyprland"
fi
