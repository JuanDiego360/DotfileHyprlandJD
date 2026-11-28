#!/usr/bin/env bash

# Ensure pactl can connect to PipeWire/PulseAudio regardless of launch context
export XDG_RUNTIME_DIR="/run/user/$(id -u)"
export PULSE_RUNTIME_PATH="$XDG_RUNTIME_DIR/pulse"

# ---------------------------------------------------------
# CACHING & MIGRATION
# ---------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

qs_ensure_cache "screenshot"
qs_ensure_cache "recording"

# ---------------------------------------------------------
# DEPENDENCY CHECK
# ---------------------------------------------------------
# First check for notify-send so we can display errors
if ! command -v notify-send &> /dev/null; then
    echo "ERROR: notify-send is not installed. Cannot display missing dependencies."
    exit 1
fi

REQUIRED_CMDS=("gpu-screen-recorder" "grim" "satty" "wl-copy" "pactl" "quickshell" "zbarimg" "python3" "tesseract")
MISSING_CMDS=()

for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &> /dev/null; then
        MISSING_CMDS+=("$cmd")
    fi
done

if [ ${#MISSING_CMDS[@]} -ne 0 ]; then
    notify-send -u critical -a "Screenshot System" "Missing Dependencies" "Cannot start. Please install:\n${MISSING_CMDS[*]}"
    exit 1
fi
# ---------------------------------------------------------

# Directories
SAVE_DIR="${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots"
RECORD_DIR="${XDG_VIDEOS_DIR:-$HOME/Videos}/Recordings"
CACHE_DIR="$QS_CACHE_RECORDING"
mkdir -p "$SAVE_DIR" "$RECORD_DIR"

# Parse arguments safely upfront
EDIT_MODE=false
FULL_MODE=false
RECORD_MODE=false
REGION_MODE=false
SCAN_QR_MODE=false
OCR_MODE=false
CLIPBOARD_MODE=false
COLOR_PICKER_MODE=false
COPY_COLOR=""
COLOR_HEX=""
COLOR_RGB=""
COLOR_HSL=""
QUIET_MODE=false
TARGET_MON=""
GEOMETRY=""

# Load saved audio preferences as defaults
PREFS="$QS_STATE_SCREENSHOT/audio_prefs"
if [ -f "$PREFS" ]; then
    IFS=',' read -r QS_DESK_VOL QS_DESK_MUTE QS_MIC_VOL QS_MIC_MUTE QS_MIC_DEV < "$PREFS"
    DESK_VOL="${QS_DESK_VOL:-1.0}"
    DESK_MUTE="${QS_DESK_MUTE:-false}"
    MIC_VOL="${QS_MIC_VOL:-1.0}"
    MIC_MUTE="${QS_MIC_MUTE:-false}"
    MIC_DEVICE="${QS_MIC_DEV:-}"
    export QS_DESK_VOL QS_DESK_MUTE QS_MIC_VOL QS_MIC_MUTE QS_MIC_DEV
else
    DESK_VOL="1.0"
    DESK_MUTE="false"
    MIC_VOL="1.0"
    MIC_MUTE="false"
    MIC_DEVICE=""
fi

while [[ "$#" -gt 0 ]]; do
    case $1 in
        --edit) EDIT_MODE=true; shift ;;
        --full) FULL_MODE=true; shift ;;
        --record) RECORD_MODE=true; shift ;;
        --region) REGION_MODE=true; shift ;;
        --scan-qr) SCAN_QR_MODE=true; shift ;;
        --ocr) OCR_MODE=true; shift ;;
        --clipboard) CLIPBOARD_MODE=true; shift ;;
        --color-picker) COLOR_PICKER_MODE=true; shift ;;
        --copy-color) COPY_COLOR="$2"; shift 2 ;;
        --color-hex) COLOR_HEX="$2"; shift 2 ;;
        --color-rgb) COLOR_RGB="$2"; shift 2 ;;
        --color-hsl) COLOR_HSL="$2"; shift 2 ;;
        --quiet) QUIET_MODE=true; shift ;;
        --monitor) TARGET_MON="$2"; shift 2 ;;
        --geometry) GEOMETRY="$2"; shift 2 ;;
        --desk-vol) DESK_VOL="$2"; shift 2 ;;
        --desk-mute) DESK_MUTE="$2"; shift 2 ;;
        --mic-vol) MIC_VOL="$2"; shift 2 ;;
        --mic-mute) MIC_MUTE="$2"; shift 2 ;;
        --mic-dev) MIC_DEVICE="$2"; shift 2 ;;
        *) shift ;;
    esac
done

# Detect focused monitor from Hyprland
FOCUSED_MON=""
if command -v hyprctl &>/dev/null; then
    if command -v jq &>/dev/null; then
        FOCUSED_MON=$(hyprctl monitors -j 2>/dev/null | jq -r '.[] | select(.focused == true) | .name' 2>/dev/null)
    fi
    if [ -z "$FOCUSED_MON" ]; then
        FOCUSED_MON=$(hyprctl monitors 2>/dev/null | awk '/Monitor/ {m=$2} /focused: yes/ {print m}')
    fi
fi

# ---------------------------------------------------------
# COLOR PICKER & COLOR COPY HANDLERS
# ---------------------------------------------------------
if [ -n "$COPY_COLOR" ]; then
    if ! command -v wl-copy &>/dev/null; then
        notify-send -u critical -a "Screenshot" "Error de dependencias" "Se requiere wl-copy para copiar colores."
        exit 1
    fi
    printf '%s' "$COPY_COLOR" | wl-copy
    if [ "$QUIET_MODE" = false ]; then
        SWATCH_PNG=""
        if [[ "$COLOR_HEX" =~ ^#[0-9A-Fa-f]{6}$ ]] && command -v python3 &>/dev/null; then
            rm -f "$QS_RUN_SCREENSHOT"/color_swatch_*.png 2>/dev/null
            SWATCH_PNG="$QS_RUN_SCREENSHOT/color_swatch_$$.png"
            python3 - "$COLOR_HEX" "$SWATCH_PNG" << 'EOF' 2>/dev/null
import math, struct, sys, zlib

hex_col = sys.argv[1].lstrip("#")
out_path = sys.argv[2]
r = int(hex_col[0:2], 16)
g = int(hex_col[2:4], 16)
b = int(hex_col[4:6], 16)
luma = (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255.0
br, bg, bb = (0, 0, 0) if luma > 0.6 else (255, 255, 255)
ba = 0.28

w = h = 64
rad = 14.0
pad = 2.0
inner_w = w / 2.0 - pad - rad
inner_h = h / 2.0 - pad - rad
cx = (w - 1) / 2.0
cy = (h - 1) / 2.0

rows = bytearray()
for y in range(h):
    rows.append(0)
    dy = abs(y - cy) - inner_h
    for x in range(w):
        dx = abs(x - cx) - inner_w
        ox = max(dx, 0.0)
        oy = max(dy, 0.0)
        dist = math.hypot(ox, oy) + min(max(dx, dy), 0.0) - rad
        cov = max(0.0, min(1.0, 0.5 - dist))
        if cov <= 0.0:
            rows.extend((0, 0, 0, 0))
        elif dist > -1.5:
            pr = int(r * (1.0 - ba) + br * ba + 0.5)
            pg = int(g * (1.0 - ba) + bg * ba + 0.5)
            pb = int(b * (1.0 - ba) + bb * ba + 0.5)
            rows.extend((pr, pg, pb, int(cov * 255 + 0.5)))
        else:
            rows.extend((r, g, b, int(cov * 255 + 0.5)))

def chunk(tag, data):
    return struct.pack(">I", len(data)) + tag + data + struct.pack(">I", zlib.crc32(tag + data) & 0xFFFFFFFF)

ihdr = struct.pack(">IIBBBBB", w, h, 8, 6, 0, 0, 0)
png = b"\x89PNG\r\n\x1a\n" + chunk(b"IHDR", ihdr) + chunk(b"IDAT", zlib.compress(bytes(rows), 6)) + chunk(b"IEND", b"")
with open(out_path, "wb") as f:
    f.write(png)
EOF
            [ -s "$SWATCH_PNG" ] || SWATCH_PNG=""
        fi
        notif_title="Color copiado al portapapeles"
        extras=()
        [ -n "$COLOR_HEX" ] && [ "$COLOR_HEX" != "$COPY_COLOR" ] && extras+=("$COLOR_HEX")
        [ -n "$COLOR_RGB" ] && [ "$COLOR_RGB" != "$COPY_COLOR" ] && extras+=("$COLOR_RGB")
        [ -n "$COLOR_HSL" ] && [ "$COLOR_HSL" != "$COPY_COLOR" ] && extras+=("$COLOR_HSL")
        if [ "${#extras[@]}" -gt 0 ]; then
            extra_line="${extras[0]}"
            for ((i = 1; i < ${#extras[@]}; i++)); do
                extra_line+=" · ${extras[$i]}"
            done
            notif_body="${COPY_COLOR}"$'\n'"${extra_line}"
        else
            notif_body="$COPY_COLOR"
        fi
        if [ -n "$SWATCH_PNG" ]; then
            notify-send -a "Screenshot" -i "$SWATCH_PNG" "$notif_title" "$notif_body"
        else
            notify-send -a "Screenshot" "$notif_title" "$notif_body"
        fi
    fi
    exit 0
fi

if [ "$COLOR_PICKER_MODE" = true ]; then
    MISSING_CP=()
    for cmd in grim wl-copy quickshell; do
        if ! command -v "$cmd" &>/dev/null; then
            MISSING_CP+=("$cmd")
        fi
    done
    if [ ${#MISSING_CP[@]} -ne 0 ]; then
        notify-send -u critical -a "Screenshot" "Error de dependencias" "No se puede iniciar el selector de color. Falta: ${MISSING_CP[*]}"
        exit 1
    fi
    if [ -z "$TARGET_MON" ]; then
        TARGET_MON="$FOCUSED_MON"
    fi
    FREEZE_IMG="$QS_RUN_SCREENSHOT/freeze_$$.png"
    if [ -n "$TARGET_MON" ]; then
        grim -o "$TARGET_MON" -l 0 "$FREEZE_IMG" 2>/dev/null || grim -l 0 "$FREEZE_IMG"
    else
        grim -l 0 "$FREEZE_IMG"
    fi
    exec quickshell ${MAIN_QML:+-p "$MAIN_QML"} ipc call screenshotOverlay colorPicker "$FREEZE_IMG" "$TARGET_MON"
fi

# ---------------------------------------------------------
# INSTANT QR SCANNING EXECUTION
# ---------------------------------------------------------
if [ "$SCAN_QR_MODE" = true ]; then
    RES_FILE="$QS_RUN_SCREENSHOT/qr_result"
    export DEBUG_LOG="$QS_LOG_DIR/qr_debug.log"
    rm -f "$RES_FILE" "$DEBUG_LOG"
    
    echo "=== QR SCAN INITIATED $(date) ===" > "$DEBUG_LOG"
    
    if ! command -v zbarimg &> /dev/null; then
        echo -e "0,0,0,0|||ERROR: zbarimg is not installed. Please install it." > "$RES_FILE"
        exit 1
    fi

    TMP_IMG="$QS_RUN_SCREENSHOT/qr_temp_$$.png"
    grim -g "$GEOMETRY" "$TMP_IMG"
    
    export XML_OUT=$(zbarimg --xml -q "$TMP_IMG" 2>>"$DEBUG_LOG")
    
    if [ -n "$XML_OUT" ]; then
        python3 << 'EOF' > "$RES_FILE"
import os, sys, logging, re
import xml.etree.ElementTree as ET

debug_log = os.environ.get("DEBUG_LOG", "/tmp/qs_qr_debug.log")
logging.basicConfig(filename=debug_log, level=logging.DEBUG, format="%(asctime)s - %(levelname)s - %(message)s")

raw_xml = os.environ.get("XML_OUT", "")
if not raw_xml.strip():
    print("0,0,0,0|||ERROR: Empty output from zbarimg. See log.")
    sys.exit(0)

try:
    xml_clean = re.sub(r'\sxmlns="[^"]+"', '', raw_xml)
    xml_clean = re.sub(r"\sxmlns='[^']+'", '', xml_clean)
    tree = ET.fromstring(xml_clean)
    
    found_any = False
    for elem in tree.iter():
        if elem.tag.endswith('symbol'):
            found_any = True
            data_text = ''
            min_x, min_y, max_x, max_y = float('inf'), float('inf'), -float('inf'), -float('inf')
            
            for child in elem:
                if child.tag.endswith('data'):
                    data_text = child.text if child.text else ''
                elif child.tag.endswith('polygon'):
                    pts_str = child.get('points', '')
                    if pts_str:
                        pt_pairs = pts_str.replace('+', '').split(' ')
                        for pair in pt_pairs:
                            if ',' in pair:
                                try:
                                    x_str, y_str = pair.split(',')
                                    x, y = int(x_str), int(y_str)
                                    min_x = min(min_x, x)
                                    max_x = max(max_x, x)
                                    min_y = min(min_y, y)
                                    max_y = max(max_y, y)
                                except ValueError:
                                    pass
            
            if min_x == float('inf'): min_x, min_y, max_x, max_y = 0, 0, 0, 0
            w, h = max_x - min_x, max_y - min_y
            encoded = data_text.replace('\\', '\\\\').replace('\n', '\\n').replace('\r', '')
            print(f"{int(min_x)},{int(min_y)},{int(w)},{int(h)}|||{encoded}")

    if not found_any: print("0,0,0,0|||NOT_FOUND")
except Exception as e:
    print(f"0,0,0,0|||ERROR: XML Parse failure: {e}. Check log.")
EOF
    else
        echo -e "0,0,0,0|||NOT_FOUND" > "$RES_FILE"
    fi
    
    rm -f "$TMP_IMG"
    exit 0
fi

# ---------------------------------------------------------
# INSTANT OCR SCANNING EXECUTION
# ---------------------------------------------------------
if [ "$OCR_MODE" = true ]; then
    RES_FILE="$QS_RUN_SCREENSHOT/ocr_result"
    export DEBUG_LOG="$QS_LOG_DIR/ocr_debug.log"
    rm -f "$RES_FILE" "$DEBUG_LOG"
    
    echo "=== OCR SCAN INITIATED $(date) ===" > "$DEBUG_LOG"
    
    if ! command -v tesseract &> /dev/null; then
        echo -e "ERROR: tesseract is not installed. Please install it." > "$RES_FILE"
        notify-send -u critical -a "OCR" "Tesseract no encontrado" "Por favor instala tesseract"
        exit 1
    fi

    TMP_IMG="$QS_RUN_SCREENSHOT/ocr_temp_$$.png"
    if [ -n "$GEOMETRY" ]; then
        grim -g "$GEOMETRY" "$TMP_IMG"
    else
        GEOM=$(slurp)
        if [ -z "$GEOM" ]; then
            exit 0
        fi
        grim -g "$GEOM" "$TMP_IMG"
    fi

    # Check available languages
    AVAILABLE_LANGS=$(tesseract --list-langs 2>/dev/null)
    OCR_LANGS=""
    if echo "$AVAILABLE_LANGS" | grep -qx "spa"; then
        OCR_LANGS="spa"
    fi
    if echo "$AVAILABLE_LANGS" | grep -qx "eng"; then
        [ -n "$OCR_LANGS" ] && OCR_LANGS="${OCR_LANGS}+eng" || OCR_LANGS="eng"
    fi
    [ -z "$OCR_LANGS" ] && OCR_LANGS="eng"

    OCR_TEXT=$(tesseract "$TMP_IMG" stdout -l "$OCR_LANGS" 2>>"$DEBUG_LOG")
    rm -f "$TMP_IMG"

    OCR_TEXT_TRIMMED=$(echo "$OCR_TEXT" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')

    if [ -n "$OCR_TEXT_TRIMMED" ]; then
        echo -n "$OCR_TEXT_TRIMMED" | wl-copy
        echo -n "$OCR_TEXT_TRIMMED" > "$RES_FILE"
        echo "$OCR_TEXT_TRIMMED"
        NOTIF_PREVIEW=$(echo "$OCR_TEXT_TRIMMED" | head -n 4)
        notify-send -a "OCR" -i "edit-copy" "Texto copiado al portapapeles" "$NOTIF_PREVIEW"
    else
        echo -n "NOT_FOUND" > "$RES_FILE"
        echo "NOT_FOUND"
        notify-send -a "OCR" "Sin texto detectado" "No se reconoció ningún texto en el área seleccionada."
    fi
    exit 0
fi

# ---------------------------------------------------------
# SMART TOGGLE: STOP RECORDING & CLEANUP VIRTUAL AUDIO
# ---------------------------------------------------------
if [ -f "$CACHE_DIR/rec_pid" ]; then
    # PREVENT OVERLAPPING EXECUTIONS
    if [ -f "$CACHE_DIR/processing.lock" ]; then exit 0; fi
    touch "$CACHE_DIR/processing.lock"

    REC_PID=$(cat "$CACHE_DIR/rec_pid")
    FINAL_FILE=$(cat "$CACHE_DIR/final_file")

    # 1. SEND STOP SIGNAL TO GPU-SCREEN-RECORDER
    [ "$REC_PID" != "0" ] && kill -SIGINT $REC_PID 2>/dev/null

    # 2. WAIT FOR GSR TO CLOSE GRACEFULLY AND FINALIZE MP4
    timeout=30
    while kill -0 $REC_PID 2>/dev/null && [ $timeout -gt 0 ]; do
        sleep 0.1
        timeout=$((timeout - 1))
    done

    # FORCE KILL IF STUCK
    [ "$REC_PID" != "0" ] && kill -9 $REC_PID 2>/dev/null

    # 3. DESTROY PIPEWIRE VIRTUAL AUDIO CABLES
    if [ -f "$CACHE_DIR/pw_modules" ]; then
        while read -r mod_id; do
            [ -n "$mod_id" ] && pactl unload-module "$mod_id" 2>/dev/null
        done < "$CACHE_DIR/pw_modules"
        rm -f "$CACHE_DIR/pw_modules"
    fi

    # 4. SEND FINAL NOTIFICATION
    if [ -f "$FINAL_FILE" ]; then
        (
            ACTION=$(notify-send -a "Screen Recorder" -i "$FINAL_FILE" -A "default=Open Folder" "⏺ Recording Saved" "File: $(basename "$FINAL_FILE")\nFolder: $RECORD_DIR")
            if [ "$ACTION" = "default" ]; then
                if command -v dolphin &> /dev/null; then
                    dolphin "$RECORD_DIR"
                else
                    xdg-open "$RECORD_DIR"
                fi
            fi
        ) &
    else
        notify-send -a "Screen Recorder" "❌ Error" "Failed to save the video file."
    fi

    # 5. INSTANT UI CLEANUP
    rm -f "$CACHE_DIR/processing.lock"
    rm -f "$CACHE_DIR/rec_pid" "$CACHE_DIR/final_file"
    exit 0
fi

time=$(date +'%Y-%m-%d-%H%M%S')
FILENAME="$SAVE_DIR/Screenshot_$time.png"
VID_FILENAME="$RECORD_DIR/Recording_$time.mp4"
CACHE_FILE="$QS_CACHE_SCREENSHOT/geometry"
MODE_CACHE_FILE="$QS_CACHE_SCREENSHOT/video_mode"

rm -f "$CACHE_DIR/processing.lock"

if [ "$REGION_MODE" = true ] || ([ "$CLIPBOARD_MODE" = true ] && [ -z "$GEOMETRY" ] && [ "$FULL_MODE" != true ]); then
    GEOMETRY=$(slurp)
    if [ -z "$GEOMETRY" ]; then
        notify-send -a "Screenshot" "Captura cancelada" "No se seleccionó ninguna región."
        exit 0
    fi
fi

# ---------------------------------------------------------
# PHASE 1: Capture Execution (GPU-Screen-Recorder + Virtual Audio)
# ---------------------------------------------------------
if [ "$FULL_MODE" = true ] || [ -n "$GEOMETRY" ]; then

    if [ "$RECORD_MODE" = true ]; then
        
        # Clear out any old module IDs
        echo -n "" > "$CACHE_DIR/pw_modules"

        DESK_SINK=$(pactl get-default-sink 2>/dev/null)
        [ -n "$DESK_SINK" ] && DESK_DEV="${DESK_SINK}.monitor" || DESK_DEV=""
        
        [ -n "$MIC_DEVICE" ] && [ "$MIC_DEVICE" != "null" ] && MIC_DEV="$MIC_DEVICE" || MIC_DEV=$(pactl get-default-source 2>/dev/null)
        MIC_DEV="${MIC_DEV:-default}"

        # If geometry is set, record the region. Otherwise, use portal.
        if [ -n "$GEOMETRY" ]; then
            GSR_GEOM=$(echo "$GEOMETRY" | awk -F '[ ,x]' '{print $3"x"$4"+"$1"+"$2}')
            GSR_ARGS=(-w "region" -region "$GSR_GEOM" -c "mp4" -f "60" -ac "aac")
        else
            GSR_ARGS=(-w "portal" -c "mp4" -f "60" -ac "aac")
        fi

        AUDIO_MIX=""

        # --- DESKTOP AUDIO VIRTUAL ROUTING ---
        if [ "$DESK_MUTE" != "true" ] && [ -n "$DESK_DEV" ]; then
            # Create a virtual sink
            D_SINK_ID=$(pactl load-module module-null-sink sink_name=qs_virt_desk sink_properties=device.description="QS_Virtual_Desk")
            # Loop the real desktop audio into the virtual sink
            D_LOOP_ID=$(pactl load-module module-loopback source="$DESK_DEV" sink=qs_virt_desk)
            
            # Linearize volume calculation (0 - 65536) to prevent PulseAudio's steep cubic drop-off at 25%
            D_VOL_INT=$(awk "BEGIN {print int(${DESK_VOL//,/.} * 65536)}")
            pactl set-sink-volume qs_virt_desk "$D_VOL_INT"
            
            # Save IDs for teardown
            echo "$D_SINK_ID" >> "$CACHE_DIR/pw_modules"
            echo "$D_LOOP_ID" >> "$CACHE_DIR/pw_modules"
            
            # Append to mixing string
            AUDIO_MIX="${AUDIO_MIX}qs_virt_desk.monitor|"
        fi

        # --- MICROPHONE VIRTUAL ROUTING ---
        if [ "$MIC_MUTE" != "true" ] && [ -n "$MIC_DEV" ]; then
            # Create a virtual sink for the mic
            M_SINK_ID=$(pactl load-module module-null-sink sink_name=qs_virt_mic sink_properties=device.description="QS_Virtual_Mic")
            # Loop the real mic into the virtual sink
            M_LOOP_ID=$(pactl load-module module-loopback source="$MIC_DEV" sink=qs_virt_mic)
            
            # Linearize volume calculation (0 - 65536) to prevent PulseAudio's steep cubic drop-off
            M_VOL_INT=$(awk "BEGIN {print int(${MIC_VOL//,/.} * 65536)}")
            pactl set-sink-volume qs_virt_mic "$M_VOL_INT"
            
            # Save IDs for teardown
            echo "$M_SINK_ID" >> "$CACHE_DIR/pw_modules"
            echo "$M_LOOP_ID" >> "$CACHE_DIR/pw_modules"
            
            # Append to mixing string
            AUDIO_MIX="${AUDIO_MIX}qs_virt_mic.monitor|"
        fi

        # Remove trailing pipe and add the single mix string to the recorder so everything stays on one track
        AUDIO_MIX=${AUDIO_MIX%|}
        if [ -n "$AUDIO_MIX" ]; then
            GSR_ARGS+=(-a "$AUDIO_MIX")
        fi

        # Execute gpu-screen-recorder
        gpu-screen-recorder "${GSR_ARGS[@]}" -o "$VID_FILENAME" > /dev/null 2>&1 &
        REC_PID=$!

        echo "$REC_PID" > "$CACHE_DIR/rec_pid"
        echo "$VID_FILENAME" > "$CACHE_DIR/final_file"

        notify-send -a "Screen Recorder" "⏺ Recording Started" "Press your shortcut again to stop."
        exit 0
    fi

    # Mode: Screenshot
    if [ -n "$GEOMETRY" ]; then
        GRIM_CMD="grim -g \"$GEOMETRY\" -"
    elif [ -n "$FOCUSED_MON" ]; then
        GRIM_CMD="grim -o \"$FOCUSED_MON\" -"
    else
        GRIM_CMD="grim -"
    fi

    if [ "$EDIT_MODE" = true ]; then
        eval $GRIM_CMD | GSK_RENDERER=gl satty --filename - --output-filename "$FILENAME" --init-tool brush --copy-command wl-copy
    elif [ "$CLIPBOARD_MODE" = true ]; then
        eval $GRIM_CMD > "$FILENAME"
        wl-copy --type image/png < "$FILENAME"
        notify-send -a "Screenshot" -i "$FILENAME" "Captura copiada al portapapeles" "La imagen se ha copiado correctamente."
        exit 0
    else
        eval $GRIM_CMD | tee "$FILENAME" | wl-copy
    fi

    if [ -s "$FILENAME" ]; then
        (
            ACTION=$(notify-send -a "Screenshot" -i "$FILENAME" -A "default=Open Folder" "Screenshot Saved" "File: Screenshot_$time.png\nFolder: $SAVE_DIR")
            if [ "$ACTION" = "default" ]; then
                if command -v dolphin &> /dev/null; then
                    dolphin "$SAVE_DIR"
                else
                    xdg-open "$SAVE_DIR"
                fi
            fi
        ) &
    fi
    exit 0
fi

# ---------------------------------------------------------
# PHASE 2: UI Trigger (Launch Standalone Quickshell Overlay)
# ---------------------------------------------------------
QML_PATH="$HOME/.config/hypr/scripts/quickshell/ScreenshotOverlay.qml"

if pgrep -f "quickshell -p $QML_PATH" > /dev/null; then
    pkill -f "quickshell -p $QML_PATH"
    exit 0
fi

if command -v pactl &> /dev/null; then
    export QS_MIC_LIST=$(pactl list sources short 2>/dev/null | awk '{print $2}' | grep -v '\.monitor$' | while IFS= read -r name; do
        desc=$(pactl list sources 2>/dev/null | awk -v n="$name" '/Name:/ { found = ($2 == n) } found && /Description:/ { sub(/^[[:space:]]*Description:[[:space:]]*/, ""); print; exit }')
        echo "$name|${desc:-$name}"
    done)
else
    export QS_MIC_LIST=""
fi

# Audio preferences are loaded and exported at the top of the script

[ "$EDIT_MODE" = true ] && export QS_SCREENSHOT_EDIT="true" || export QS_SCREENSHOT_EDIT="false"
[ -f "$CACHE_FILE" ] && export QS_CACHED_GEOM=$(cat "$CACHE_FILE") || export QS_CACHED_GEOM=""
[ -f "$MODE_CACHE_FILE" ] && export QS_CACHED_MODE=$(cat "$MODE_CACHE_FILE") || export QS_CACHED_MODE="false"
[ -n "$FOCUSED_MON" ] && export QS_TARGET_MON="${QS_TARGET_MON:-$FOCUSED_MON}"

quickshell -p "$QML_PATH"
