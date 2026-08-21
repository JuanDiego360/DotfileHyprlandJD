#!/usr/bin/env bash

source "$(dirname "${BASH_SOURCE[0]}")/caching.sh"

# Intervalo de comprobación en segundos (900s = 15 minutos)
INTERVAL=900

# Archivo de caché para no enviar notificaciones repetidas
CACHE_FILE="$QS_CACHE_UPDATER/notified_count"
# Archivo de estado para que la barra superior muestre el botón de actualización
PENDING_FILE="$QS_CACHE_UPDATER/update_pending"
DETAILS_FILE="$QS_CACHE_UPDATER/updates_summary.txt"

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

while true; do
    check_system_updates
    sleep "$INTERVAL"
done
