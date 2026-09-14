#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

# Asegurar directorios de caché y estado persistente
qs_ensure_cache "updater"

# Intervalo mínimo entre comprobaciones en segundos (86400s = 24 horas / 1 día completo)
INTERVAL=86400

# Archivos de caché volátil
CACHE_FILE="$QS_CACHE_UPDATER/notified_count"
PENDING_FILE="$QS_CACHE_UPDATER/update_pending"
DETAILS_FILE="$QS_CACHE_UPDATER/updates_summary.txt"

# Archivos de estado persistente (sobreviven a reinicios y apagados en ~/.local/state/quickshell/updater)
STATE_DIR="$QS_STATE_UPDATER"
mkdir -p "$STATE_DIR" "$QS_CACHE_UPDATER"
LAST_UPDATE_FILE="$STATE_DIR/last_update_date"
LAST_CHECK_FILE="$STATE_DIR/last_check_date"
LAST_CHECK_TIMESTAMP_FILE="$STATE_DIR/last_check_timestamp"

# Obtiene la fecha/hora en segundos epoch de la última actualización real del sistema
get_last_update_timestamp() {
    local ts=0

    # 1. Desde el archivo de estado persistente guardado por update_system.sh
    if [[ -f "$LAST_CHECK_TIMESTAMP_FILE" ]]; then
        local saved_ts
        saved_ts=$(cat "$LAST_CHECK_TIMESTAMP_FILE" 2>/dev/null)
        [[ "$saved_ts" =~ ^[0-9]+$ ]] && ts=$saved_ts
    fi

    # 2. Desde /var/log/pacman.log por si se actualizó manualmente con pacman o yay por terminal
    local last_trans
    last_trans=$(grep "transaction completed" /var/log/pacman.log 2>/dev/null | tail -n 1)
    if [[ -n "$last_trans" ]]; then
        local iso_time trans_epoch
        iso_time=$(echo "$last_trans" | grep -o '[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}T[0-9]\{2\}:[0-9]\{2\}:[0-9]\{2\}[+-][0-9]\{4\}')
        if [[ -n "$iso_time" ]]; then
            trans_epoch=$(date -d "$iso_time" +%s 2>/dev/null)
            if [[ -n "$trans_epoch" && "$trans_epoch" -gt "$ts" ]]; then
                ts=$trans_epoch
            fi
        fi
    fi

    echo "$ts"
}

# Comprueba si el sistema ya fue actualizado hoy en el calendario local
was_updated_today() {
    local today
    today=$(date +%Y-%m-%d)

    # Comprobar archivo de estado
    if [[ -f "$LAST_UPDATE_FILE" ]]; then
        local saved_date
        saved_date=$(cat "$LAST_UPDATE_FILE" 2>/dev/null)
        if [[ "$saved_date" == "$today" ]]; then
            return 0
        fi
    fi

    # Comprobar si hubo transacción de pacman hoy
    local last_trans
    last_trans=$(grep "transaction completed" /var/log/pacman.log 2>/dev/null | tail -n 1)
    if [[ -n "$last_trans" ]]; then
        local pacman_date
        pacman_date=$(echo "$last_trans" | grep -o '\[[0-9]\{4\}-[0-9]\{2\}-[0-9]\{2\}' | tr -d '[')
        if [[ "$pacman_date" == "$today" ]]; then
            echo "$today" > "$LAST_UPDATE_FILE" 2>/dev/null
            return 0
        fi
    fi

    return 1
}

# Comprueba si ya se realizó la comprobación en el día actual
was_checked_today() {
    local today
    today=$(date +%Y-%m-%d)
    if [[ -f "$LAST_CHECK_FILE" ]]; then
        local saved_date
        saved_date=$(cat "$LAST_CHECK_FILE" 2>/dev/null)
        if [[ "$saved_date" == "$today" ]]; then
            return 0
        fi
    fi
    return 1
}

# Calcula los segundos hasta las 00:05 AM de mañana
get_seconds_until_tomorrow() {
    local now tomorrow_sec
    now=$(date +%s)
    tomorrow_sec=$(date -d "tomorrow 00:05:00" +%s 2>/dev/null)
    if [[ -n "$tomorrow_sec" && "$tomorrow_sec" -gt "$now" ]]; then
        echo $((tomorrow_sec - now))
    else
        echo "$INTERVAL"
    fi
}

check_system_updates() {
    local pacman_count=0
    local aur_count=0
    local flatpak_count=0
    local pacman_list=""
    local aur_list=""

    # 1. Comprobar repositorios oficiales con checkupdates (seguro, no bloquea pacman)
    if command -v checkupdates &>/dev/null; then
        pacman_list=$(checkupdates 2>/dev/null)
        if [[ -n "$pacman_list" ]]; then
            pacman_count=$(echo "$pacman_list" | grep -c .)
        fi
    fi

    # 2. Comprobar AUR (yay o paru)
    if command -v yay &>/dev/null; then
        aur_list=$(yay -Qua 2>/dev/null)
        if [[ -n "$aur_list" ]]; then
            aur_count=$(echo "$aur_list" | grep -c .)
        fi
    elif command -v paru &>/dev/null; then
        aur_list=$(paru -Qua 2>/dev/null)
        if [[ -n "$aur_list" ]]; then
            aur_count=$(echo "$aur_list" | grep -c .)
        fi
    fi

    # 3. Comprobar Flatpak
    if command -v flatpak &>/dev/null; then
        flatpak_count=$(flatpak remote-ls --updates 2>/dev/null | grep -c .)
    fi

    # 4. Comprobar Dotfiles (si existe versión local)
    local dots_pending=0
    if [ -f "$HOME/.local/state/imperative-dots-version" ]; then
        local local_dots
        local_dots=$(source "$HOME/.local/state/imperative-dots-version" 2>/dev/null && echo "$LOCAL_VERSION")
        if [[ -n "$local_dots" && "$local_dots" != "Unknown" ]]; then
            local remote_dots
            remote_dots=$(curl -m 5 -s https://raw.githubusercontent.com/ilyamiro/imperative-dots/master/install.sh 2>/dev/null | grep '^DOTS_VERSION=' | cut -d'"' -f2)
            if [[ -n "$remote_dots" && "$local_dots" != "$remote_dots" ]]; then
                local newest
                newest=$(printf '%s\n' "$local_dots" "$remote_dots" | sort -V | tail -n1)
                if [[ "$newest" == "$remote_dots" ]]; then
                    dots_pending=1
                fi
            fi
        fi
    fi

    local total=$((pacman_count + aur_count + flatpak_count + dots_pending))

    # Guardar resumen de actualizaciones
    {
        echo "TOTAL=$total"
        echo "PACMAN=$pacman_count"
        echo "AUR=$aur_count"
        echo "FLATPAK=$flatpak_count"
        echo "DOTS=$dots_pending"
        echo "CHECKED_AT=$(date +'%Y-%m-%d %H:%M:%S')"
    } > "$DETAILS_FILE" 2>/dev/null

    if (( total > 0 )); then
        # Activar el icono en la barra superior
        touch "$PENDING_FILE"

        # Notificar solo si cambió la cantidad de actualizaciones
        local last_notified=""
        [[ -f "$CACHE_FILE" ]] && last_notified=$(cat "$CACHE_FILE" 2>/dev/null)

        if [[ "$last_notified" != "$total" ]]; then
            echo "$total" > "$CACHE_FILE"

            local msg=""
            (( pacman_count > 0 )) && msg+="Pacman: $pacman_count  "
            (( aur_count > 0 )) && msg+="AUR: $aur_count  "
            (( flatpak_count > 0 )) && msg+="Flatpak: $flatpak_count  "
            (( dots_pending > 0 )) && msg+="Dotfiles: 1  "

            notify-send -t 12000 -a 'Actualizaciones' -u normal \
                "Actualizaciones disponibles ($total)" \
                "$msg\nHaz clic en el icono de la barra para actualizar."
        fi
    else
        # Limpiar banderas si no hay actualizaciones
        rm -f "$PENDING_FILE"
        rm -f "$CACHE_FILE"
    fi
}

# Ejecución principal (protegida si el script se carga con source)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Pausa inicial de 30 segundos tras arrancar Hyprland para permitir que la red (Wi-Fi) conecte
    sleep 30

    while true; do
        today=$(date +%Y-%m-%d)
        now=$(date +%s)
        last_update_ts=$(get_last_update_timestamp)
        elapsed=$((now - last_update_ts))

        # 1. Si se actualizó hace menos de 24 horas (86400 segundos), esperar el tiempo restante
        if (( last_update_ts > 0 && elapsed < INTERVAL )); then
            remaining=$((INTERVAL - elapsed))
            rm -f "$PENDING_FILE"
            rm -f "$CACHE_FILE"
            sleep "$remaining"
            continue
        fi

        # 2. Si ya fue actualizado hoy en el calendario, limpiar banderas y esperar a mañana
        if was_updated_today; then
            rm -f "$PENDING_FILE"
            rm -f "$CACHE_FILE"
            sleep_time=$(get_seconds_until_tomorrow)
            sleep "$sleep_time"
            continue
        fi

        # 3. Si ya se realizó la comprobación hoy, no volver a comprobar en cada encendido del mismo día
        if was_checked_today; then
            sleep_time=$(get_seconds_until_tomorrow)
            sleep "$sleep_time"
            continue
        fi

        # 4. Comprobación diaria del sistema
        check_system_updates

        # Guardar marcas de la comprobación
        echo "$today" > "$LAST_CHECK_FILE" 2>/dev/null
        date +%s > "$LAST_CHECK_TIMESTAMP_FILE" 2>/dev/null

        # Dormir hasta mañana o intervalo
        sleep_time=$(get_seconds_until_tomorrow)
        sleep "$sleep_time"
    done
fi
