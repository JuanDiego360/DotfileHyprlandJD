#!/bin/bash
SHADER="/home/juandiego/.config/hypr/shaders/olive_green.glsl"
CURRENT=$(hyprctl getoption decoration:screen_shader -j | jq -r '.str')

if [ "$CURRENT" = "$SHADER" ]; then
    hyprctl keyword decoration:screen_shader "[[EMPTY]]"
    notify-send 'Filtro Verde Oliva' 'Desactivado' -a 'Hyprland'
else
    hyprctl keyword decoration:screen_shader "$SHADER"
    notify-send 'Filtro Verde Oliva' 'Activado' -a 'Hyprland'
fi
