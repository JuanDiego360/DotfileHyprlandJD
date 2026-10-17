#!/usr/bin/env bash

# -----------------------------------------------------------------------------
# CACHING & MIGRATION
# -----------------------------------------------------------------------------
source "$(dirname "${BASH_SOURCE[0]}")/../../caching.sh"
qs_ensure_cache "weather"

# Force standard C locale for number formatting and date parsing (fixes printf and date command issues on varying OS locales)
export LC_ALL=C

# Paths
cache_dir="$QS_CACHE_WEATHER"
json_file="${cache_dir}/weather.json"
view_file="${cache_dir}/view_id"
daily_cache_file="${cache_dir}/daily_weather_cache.json"
next_day_cache_file="${cache_dir}/next_day_precache.json"
ENV_FILE="$(dirname "$0")/.env"

# API Settings
# Load environment variables silently
if [ -f "$ENV_FILE" ]; then
    export $(grep -v '^#' "$ENV_FILE" | xargs)
fi

# API Settings from .env
KEY="$OPENWEATHER_KEY"
ID="$OPENWEATHER_CITY_ID"
UNIT="${OPENWEATHER_UNIT:-metric}" # Default to metric if not set

# Determine temperature symbol based on unit
case "$UNIT" in
    "imperial") UNIT_SYM="°F" ;;
    "standard") UNIT_SYM="K" ;;
    *) UNIT_SYM="°C" ;;
esac

mkdir -p "${cache_dir}"

get_icon() {
    case $1 in
        "50d"|"50n") icon="󰖑"; quote="Mist" ;;
        "01d") icon=""; quote="Sunny" ;;
        "01n") icon=""; quote="Clear" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") icon=""; quote="Cloudy" ;;
        "09d"|"09n"|"10d"|"10n") icon="󰖗"; quote="Rainy" ;;
        "11d"|"11n") icon=""; quote="Storm" ;;
        "13d"|"13n") icon=""; quote="Snow" ;;
        *) icon=""; quote="Unknown" ;;
    esac
    echo "$icon|$quote"
}

get_hex() {
    case $1 in
        "50d"|"50n") echo "#84afdb" ;;
        "01d") echo "#f9e2af" ;;
        "01n") echo "#cba6f7" ;;
        "02d"|"02n"|"03d"|"03n"|"04d"|"04n") echo "#bac2de" ;;
        "09d"|"09n"|"10d"|"10n") echo "#74c7ec" ;;
        "11d"|"11n") echo "#f9e2af" ;;
        "13d"|"13n") echo "#cdd6f4" ;;
        *) echo "#cdd6f4" ;;
    esac
}

write_dummy_data() {
    final_json="["
    for i in {0..4}; do
        future_date=$(date -d "+$i days")
        f_day=$(date -d "$future_date" "+%a")
        f_full_day=$(date -d "$future_date" "+%A")
        f_date_num=$(date -d "$future_date" "+%d %b")
        
        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"0.0\",
            \"min\": \"0.0\",
            \"feels_like\": \"0.0\",
            \"wind\": \"0\",
            \"humidity\": \"0\",
            \"pop\": \"0\",
            \"icon\": \"\",
            \"hex\": \"#cdd6f4\",
            \"desc\": \"No API Key\",
            \"hourly\": [{\"time\": \"00:00\", \"temp\": \"0.0\", \"icon\": \"\", \"hex\": \"#cdd6f4\"}]
        },"
    done
    final_json="${final_json%,}]"
    echo "{ \"current_temp\": \"0.0\", \"current_icon\": \"\", \"current_hex\": \"#cdd6f4\", \"forecast\": ${final_json} }" > "${json_file}"
}

get_ow_icon_from_wwo() {
    local code=$1
    case $code in
        113) echo "01d" ;; # Sunny/Clear
        116) echo "02d" ;; # Partly Cloudy
        119|122) echo "03d" ;; # Cloudy/Overcast
        143|248|260) echo "50d" ;; # Mist/Fog
        200|386|389|392|395) echo "11d" ;; # Thunderstorm
        179|182|185|227|230|281|284|317|320|323|326|329|332|335|338|350|362|365|368|371|374|377|395) echo "13d" ;; # Snow
        *) echo "09d" ;; # default to rain/showers for others
    esac
}

get_data() {
    raw_api=$(curl -sf "http://wttr.in/?format=j1")
    if [ -z "$raw_api" ]; then
        if [ ! -f "$json_file" ]; then
            write_dummy_data
        fi
        return
    fi

    # Parse current weather conditions
    c_temp=$(echo "$raw_api" | jq -r '.current_condition[0].temp_C')
    c_temp=$(printf "%.1f" "$c_temp")
    wwo_code=$(echo "$raw_api" | jq -r '.current_condition[0].weatherCode')
    c_code=$(get_ow_icon_from_wwo "$wwo_code")
    c_icon=$(get_icon "$c_code" | cut -d'|' -f1)
    c_hex=$(get_hex "$c_code")

    # Build forecast array of 5 days (wttr.in returns 3 days)
    final_json="["
    for i in {0..4}; do
        idx=$i
        if [ $idx -gt 2 ]; then idx=2; fi

        day_obj=$(echo "$raw_api" | jq ".weather[$idx]")
        
        d=$(echo "$day_obj" | jq -r '.date')
        if [ $i -gt 2 ]; then
            diff=$((i - 2))
            d=$(date -d "$d +$diff days" +%Y-%m-%d)
        fi

        raw_max=$(echo "$day_obj" | jq -r '.maxtempC')
        f_max_temp=$(printf "%.1f" "$raw_max")

        raw_min=$(echo "$day_obj" | jq -r '.mintempC')
        f_min_temp=$(printf "%.1f" "$raw_min")

        f_feels_like=$f_max_temp
        f_wind=$(echo "$day_obj" | jq -r '.hourly[4].windspeedKmph')
        f_hum=$(echo "$day_obj" | jq -r '.hourly[4].humidity')
        f_pop=$(echo "$day_obj" | jq -r '.hourly[4].chanceofrain')
        
        wwo_f_code=$(echo "$day_obj" | jq -r '.hourly[4].weatherCode')
        f_code=$(get_ow_icon_from_wwo "$wwo_f_code")
        
        f_desc=$(echo "$day_obj" | jq -r '.hourly[4].weatherDesc[0].value')
        f_icon_data=$(get_icon "$f_code")
        f_icon=$(echo "$f_icon_data" | cut -d'|' -f1)
        f_hex=$(get_hex "$f_code")
        
        f_day=$(date -d "$d" "+%a")
        f_full_day=$(date -d "$d" "+%A")
        f_date_num=$(date -d "$d" "+%d %b")

        hourly_json="["
        for h in {0..7}; do
            slot_item=$(echo "$day_obj" | jq ".hourly[$h]")
            raw_s_temp=$(echo "$slot_item" | jq -r ".tempC")
            s_temp=$(printf "%.1f" "$raw_s_temp")
            
            s_time_raw=$(echo "$slot_item" | jq -r ".time")
            s_time=$(printf "%02d:00" $((s_time_raw / 100)))
            
            s_wwo_code=$(echo "$slot_item" | jq -r ".weatherCode")
            s_code=$(get_ow_icon_from_wwo "$s_wwo_code")
            s_hex=$(get_hex "$s_code")
            s_icon=$(get_icon "$s_code" | cut -d'|' -f1)
            
            hourly_json="${hourly_json} {\"time\": \"${s_time}\", \"temp\": \"${s_temp}\", \"icon\": \"${s_icon}\", \"hex\": \"${s_hex}\"},"
        done
        hourly_json="${hourly_json%,}]"

        final_json="${final_json} {
            \"id\": \"${i}\",
            \"day\": \"${f_day}\",
            \"day_full\": \"${f_full_day}\",
            \"date\": \"${f_date_num}\",
            \"max\": \"${f_max_temp}\",
            \"min\": \"${f_min_temp}\",
            \"feels_like\": \"${f_feels_like}\",
            \"wind\": \"${f_wind}\",
            \"humidity\": \"${f_hum}\",
            \"pop\": \"${f_pop}\",
            \"icon\": \"${f_icon}\",
            \"hex\": \"${f_hex}\",
            \"desc\": \"${f_desc}\",
            \"hourly\": ${hourly_json}
        },"
    done
    final_json="${final_json%,}]"

    echo "{ \"current_temp\": \"${c_temp}\", \"current_icon\": \"${c_icon}\", \"current_hex\": \"${c_hex}\", \"forecast\": ${final_json} }" > "${json_file}"
}

# --- MODE HANDLING ---
if [[ "$1" == "--getdata" ]]; then
    get_data

elif [[ "$1" == "--json" ]]; then
    CACHE_LIMIT=900         # 15 minutes for valid working data
    PENDING_RETRY_LIMIT=3600 # 1 hour for invalid/activating keys

    if [ -f "$json_file" ]; then
        file_time=$(stat -c %Y "$json_file")
        current_time=$(date +%s)
        diff=$((current_time - file_time))
        
        if grep -q '"desc": "No API Key"' "$json_file"; then
            # Key is pending/invalid. Check once an hour.
            if [ $diff -gt $PENDING_RETRY_LIMIT ]; then
                touch "$json_file" # Bump file timestamp slightly to avoid spamming processes
                get_data &
            fi
        else
            # Normal working API key. Check every 15 mins.
            if [ $diff -gt $CACHE_LIMIT ]; then
                touch "$json_file"
                get_data &
            fi
        fi
        cat "$json_file"
    else
        get_data
        cat "$json_file"
    fi

elif [[ "$1" == "--view-listener" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    tail -F "$view_file"

elif [[ "$1" == "--nav" ]]; then
    if [ ! -f "$view_file" ]; then echo "0" > "$view_file"; fi
    current=$(cat "$view_file")
    direction=$2
    max_idx=4
    if [[ "$direction" == "next" ]]; then
        if [ "$current" -lt "$max_idx" ]; then
            new=$((current + 1))
            echo "$new" > "$view_file"
        fi
    elif [[ "$direction" == "prev" ]]; then
        if [ "$current" -gt 0 ]; then
            new=$((current - 1))
            echo "$new" > "$view_file"
        fi
    fi

elif [[ "$1" == "--icon" ]]; then
    cat "$json_file" | jq -r '.forecast[0].icon'

elif [[ "$1" == "--temp" ]]; then 
    t=$(cat "$json_file" | jq -r '.forecast[0].max')
    echo "${t}${UNIT_SYM}"

elif [[ "$1" == "--hex" ]]; then 
    cat "$json_file" | jq -r '.forecast[0].hex'

elif [[ "$1" == "--current-icon" ]]; then
    icon=$(cat "$json_file" | jq -r '.current_icon // empty')
    if [[ -z "$icon" || "$icon" == "null" ]]; then 
        get_data
        icon=$(cat "$json_file" | jq -r '.current_icon')
    fi
    echo "$icon"

elif [[ "$1" == "--current-temp" ]]; then 
    t=$(cat "$json_file" | jq -r '.current_temp // empty')
    if [[ -z "$t" || "$t" == "null" ]]; then 
        get_data
        t=$(cat "$json_file" | jq -r '.current_temp')
    fi
    echo "${t}${UNIT_SYM}"

elif [[ "$1" == "--current-hex" ]]; then
    hex=$(cat "$json_file" | jq -r '.current_hex // empty')
    if [[ -z "$hex" || "$hex" == "null" ]]; then 
        get_data
        hex=$(cat "$json_file" | jq -r '.current_hex')
    fi
    echo "$hex"
fi
