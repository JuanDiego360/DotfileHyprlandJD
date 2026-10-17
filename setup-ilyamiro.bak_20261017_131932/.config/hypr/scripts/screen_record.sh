#!/usr/bin/env bash

# Directorio de guardado
SAVE_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
mkdir -p "$SAVE_DIR"

PID_FILE="/tmp/hypr_recorder.pid"
INFO_FILE="/tmp/hypr_recorder.info"

# ---------------------------------------------------------
# SI YA HAY UNA GRABACIÓN EN CURSO -> DETENER Y GUARDAR
# ---------------------------------------------------------
if [ -f "$PID_FILE" ] && kill -0 "$(cat "$PID_FILE")" 2>/dev/null; then
    REC_PID=$(cat "$PID_FILE")
    rm -f "$PID_FILE"
    
    # Enviar SIGINT para cerrar limpiamente el archivo mp4
    kill -SIGINT "$REC_PID" 2>/dev/null
    
    # Esperar hasta 5 segundos a que finalice
    timeout=50
    while kill -0 "$REC_PID" 2>/dev/null && [ $timeout -gt 0 ]; do
        sleep 0.1
        timeout=$((timeout - 1))
    done
    
    FILE_SAVED=""
    if [ -f "$INFO_FILE" ]; then
        FILE_SAVED=$(cat "$INFO_FILE")
        rm -f "$INFO_FILE"
    fi
    
    if [ -n "$FILE_SAVED" ] && [ -f "$FILE_SAVED" ]; then
        notify-send -a "Grabador de Pantalla" -i "$FILE_SAVED" "⏺ Grabación Guardada" "Guardada en: $FILE_SAVED"
    else
        notify-send -a "Grabador de Pantalla" "⏺ Grabación Finalizada" "El vídeo se ha guardado en $SAVE_DIR"
    fi
    exit 0
fi

# Limpieza preventiva por si quedó un PID colgado
rm -f "$PID_FILE" "$INFO_FILE"

# ---------------------------------------------------------
# MENÚ ROFI PARA SELECCIONAR MODO DE AUDIO
# ---------------------------------------------------------
OPTIONS="🔊 Audio del Sistema (PC)\n🎙️ Micrófono\n🎧 Sistema + Micrófono\n🔇 Sin Audio"

SELECTION=$(echo -e "$OPTIONS" | rofi -dmenu -p "Modo de Audio" -i)

if [ -z "$SELECTION" ]; then
    notify-send -a "Grabador de Pantalla" "Grabación cancelada" "No se seleccionó modo de audio."
    exit 0
fi

AUDIO_ARG=""
case "$SELECTION" in
    *"Audio del Sistema"*)
        AUDIO_ARG="-a default_output"
        ;;
    *"Micrófono"*)
        AUDIO_ARG="-a default_input"
        ;;
    *"Sistema + Micrófono"*)
        AUDIO_ARG="-a default_output|default_input"
        ;;
    *"Sin Audio"*)
        AUDIO_ARG=""
        ;;
    *)
        notify-send -a "Grabador de Pantalla" "Grabación cancelada"
        exit 0
        ;;
esac

# ---------------------------------------------------------
# SELECCIONAR REGIÓN DE PANTALLA (SLURP)
# ---------------------------------------------------------
GEOMETRY=$(slurp)

if [ -z "$GEOMETRY" ]; then
    notify-send -a "Grabador de Pantalla" "Grabación cancelada" "No se seleccionó área de pantalla."
    exit 0
fi

TIMESTAMP=$(date +'%Y-%m-%d_%H-%M-%S')
OUTPUT_FILE="$SAVE_DIR/Recording_$TIMESTAMP.mp4"
echo "$OUTPUT_FILE" > "$INFO_FILE"

# ---------------------------------------------------------
# INICIAR GRABACIÓN CON GPU-SCREEN-RECORDER O WF-RECORDER
# ---------------------------------------------------------
if command -v gpu-screen-recorder &>/dev/null; then
    # Convertir formato de slurp (X,Y WxH) a gpu-screen-recorder (WxH+X+Y)
    GSR_GEOM=$(echo "$GEOMETRY" | awk -F '[ ,x]' '{print $3"x"$4"+"$1"+"$2}')
    gpu-screen-recorder -w region -region "$GSR_GEOM" -c mp4 -f 60 -ac aac $AUDIO_ARG -o "$OUTPUT_FILE" > /dev/null 2>&1 &
    REC_PID=$!
else
    # Respaldo con wf-recorder
    WF_AUDIO=""
    if [[ "$AUDIO_ARG" == *"default_output"* ]]; then
        DESK_DEV=$(pactl get-default-sink 2>/dev/null).monitor
        WF_AUDIO="--audio=$DESK_DEV"
    elif [[ "$AUDIO_ARG" == *"default_input"* ]]; then
        MIC_DEV=$(pactl get-default-source 2>/dev/null)
        WF_AUDIO="--audio=$MIC_DEV"
    fi
    wf-recorder -g "$GEOMETRY" $WF_AUDIO -f "$OUTPUT_FILE" > /dev/null 2>&1 &
    REC_PID=$!
fi

echo "$REC_PID" > "$PID_FILE"

notify-send -a "Grabador de Pantalla" "⏺ Grabación Iniciada" "Modo: $SELECTION\nPresiona SUPER + ALT + R para finalizar."
