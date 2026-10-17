#!/usr/bin/env bash

# Clear terminal screen
clear

echo "========================================================"
echo "   ACTUALIZACIÓN COMPLETA DEL SISTEMA Y LIMPIEZA (CachyOS)"
echo "========================================================"
echo

# Variables de entorno para compilación de paquetes Rust/Cargo desde AUR
export CARGO_NET_GIT_FETCH_WITH_CLI=true

# -----------------------------------------------------------------------------
# 0. Verificación preventiva de compatibilidad de Hyprland (Transición a 0.57+)
# -----------------------------------------------------------------------------
echo "--> 0. Verificando compatibilidad de versiones de Hyprland..."
hypr_update=""

if grep -q -E "^IgnorePkg\s*=.*hyprland" /etc/pacman.conf 2>/dev/null; then
    echo "       [PROTEGIDO] Hyprland está pausado en /etc/pacman.conf (IgnorePkg activo)."
    echo "                   Las actualizaciones mayores no afectarán tu entorno."
else
    if command -v checkupdates &>/dev/null; then
        hypr_update=$(checkupdates 2>/dev/null | grep -E '^(hyprland|hyprland-git|hyprland-nvidia|hyprland-nvidia-git) ' | head -n 1 || true)
    fi

    if [[ -z "$hypr_update" ]] && command -v yay &>/dev/null; then
        hypr_update=$(yay -Qua 2>/dev/null | grep -E '^(hyprland|hyprland-git|hyprland-nvidia|hyprland-nvidia-git) ' | head -n 1 || true)
    fi

    if [[ -z "$hypr_update" ]]; then
        hypr_update=$(pacman -Qu 2>/dev/null | grep -E '^(hyprland|hyprland-git|hyprland-nvidia|hyprland-nvidia-git) ' | head -n 1 || true)
    fi

    if [[ -n "$hypr_update" ]]; then
        new_hypr_ver=$(echo "$hypr_update" | awk -F'->' '{print $2}' | awk '{print $1}')
        installed_hypr_ver=$(pacman -Q hyprland hyprland-git hyprland-nvidia 2>/dev/null | head -n 1 | awk '{print $2}')
        if [[ -n "$new_hypr_ver" ]] && command -v vercmp &>/dev/null; then
            # Solo alertar durante el salto de transición si la versión actual aún es < 0.57
            if [ -n "$installed_hypr_ver" ] && [ "$(vercmp "$installed_hypr_ver" "0.57.0")" -lt 0 ] && [ "$(vercmp "$new_hypr_ver" "0.57.0")" -ge 0 ]; then
                echo
                echo "════════════════════════════════════════════════════════════════════════"
                echo "  🚨 ¡ALERTA PREVENTIVA CRÍTICA: HYPRLAND $new_hypr_ver DETECTADO! 🚨"
                echo "════════════════════════════════════════════════════════════════════════"
                echo "  Se ha detectado una versión de Hyprland >= 0.57 lista para instalar."
                echo "  A partir de la versión 0.57, Hyprland ELIMINA el soporte de archivos .conf"
                echo "  y pasa obligatoriamente al nuevo formato de configuración en Lua."
                echo
                echo "  ⚠️  PELIGRO: Si actualizas ahora sin tener migrados tus dotfiles,"
                echo "  tu entorno gráfico NO podrá cargar tu configuración (atajos, barra, etc)."
                echo "════════════════════════════════════════════════════════════════════════"
                echo
                echo "  [1] Cancelar la actualización (RECOMENDADO para proteger tu entorno)"
                echo "  [2] Pausar Hyprland (IgnorePkg) y continuar con el resto del sistema"
                echo "  [3] Continuar con la actualización completa (Bajo tu propia responsabilidad)"
                echo
                read -rp "Selecciona una opción [1/2/3] (Por defecto: 1): " hypr_choice
                hypr_choice=${hypr_choice:-1}

                case "$hypr_choice" in
                    2)
                        echo
                        echo "--> Configurando IgnorePkg en /etc/pacman.conf para proteger Hyprland..."
                        if grep -q -E "^IgnorePkg\s*=" /etc/pacman.conf; then
                            if ! grep -q -E "^IgnorePkg\s*=.*hyprland" /etc/pacman.conf; then
                                sudo sed -i -E 's/^(IgnorePkg\s*=.*)/\1 hyprland hyprland-git hyprland-nvidia hyprland-nvidia-git/' /etc/pacman.conf
                            fi
                        else
                            if grep -q -E "^#IgnorePkg\s*=" /etc/pacman.conf; then
                                sudo sed -i -E 's/^#IgnorePkg\s*=.*/IgnorePkg = hyprland hyprland-git hyprland-nvidia hyprland-nvidia-git/' /etc/pacman.conf
                            else
                                echo "IgnorePkg = hyprland hyprland-git hyprland-nvidia hyprland-nvidia-git" | sudo tee -a /etc/pacman.conf > /dev/null
                            fi
                        fi
                        echo "✅ Hyprland ha sido pausado. Se actualizará el resto del sistema de forma segura."
                        echo
                        ;;
                    3)
                        echo
                        echo "⚠️  Continuando con la actualización completa bajo tu propio riesgo..."
                        echo
                        ;;
                    *)
                        echo
                        echo "❌ Actualización cancelada. Tus dotfiles y entorno permanecen a salvo."
                        echo "   Cuando estés listo para migrar a Lua, podrás retomar la actualización."
                        echo
                        read -n 1 -s -r -p "Presiona cualquier tecla para salir..."
                        echo
                        exit 0
                        ;;
                esac
            else
                echo "       [OK] Hyprland $new_hypr_ver es compatible con la sintaxis .conf actual."
            fi
        fi
    else
        echo "       [OK] No hay actualizaciones pendientes que rompan compatibilidad."
    fi
fi
echo

# 1. Actualización exclusiva con la herramienta nativa de CachyOS (cachy-update)
# Nota: cachy-update se encarga automáticamente de los repositorios optimizados, oficiales y de AUR (vía yay/paru)
if ! command -v cachy-update &> /dev/null; then
    echo "--> 1. Instalando la herramienta nativa 'cachy-update'..."
    sudo pacman -S --needed --noconfirm cachy-update
fi

echo "--> 1. Sincronizando y actualizando el sistema con 'cachy-update'..."
echo "       (Gestiona repositorios oficiales, optimizaciones CachyOS y AUR automáticamente)"
cachy-update

# 2. Actualización de Flatpak (si existe)
if command -v flatpak &> /dev/null; then
    echo
    echo "--> 2. Buscando y aplicando actualizaciones de Flatpak..."
    if ! flatpak update -y; then
        echo "Reintentando actualización de Flatpak sin diferencias estáticas (--no-static-deltas)..."
        flatpak update -y --no-static-deltas
    fi
fi

# 3. Limpieza del sistema
echo
echo "--> 3. Realizando tareas de limpieza..."

# Huérfanos de pacman
orphans=$(pacman -Qtdq 2>/dev/null)
if [ -n "$orphans" ]; then
    echo "Eliminando paquetes huérfanos de Pacman: $orphans"
    # shellcheck disable=SC2086
    sudo pacman -Rns $orphans --noconfirm
else
    echo "No hay paquetes huérfanos de Pacman para eliminar."
fi

# Limpieza de dependencias innecesarias con yay
if command -v yay &> /dev/null; then
    echo "Limpiando dependencias innecesarias de yay (yay -Yc)..."
    yay -Yc --noconfirm 2>/dev/null || true
fi

# Limpieza de caché de paquetes (mantiene las últimas 2 versiones)
if command -v paccache &> /dev/null; then
    echo "Limpiando caché de paquetes antigua (paccache -r)..."
    sudo paccache -r
else
    echo "Limpiando caché de pacman (pacman -Scc)..."
    sudo pacman -Scc --noconfirm
fi

# Limpieza de Flatpak unused runtimes
if command -v flatpak &> /dev/null; then
    echo "Eliminando runtimes y aplicaciones Flatpak sin usar..."
    flatpak uninstall --unused -y 2>/dev/null || true
fi

# 4. Comprobación de reinicio y kernels
echo
echo "--> 4. Comprobando estado del kernel y reinicio del sistema..."
reboot_needed=false
running_kernel=$(uname -r)

if [ ! -d "/usr/lib/modules/$running_kernel" ]; then
    reboot_needed=true
    echo "⚠️  ¡El kernel actual ha sido actualizado! (Kernel en ejecución: $running_kernel)"
fi

# Buscar si se actualizaron paquetes críticos en la última transacción de pacman
last_upgrade_logs=$(tail -n 100 /var/log/pacman.log 2>/dev/null | grep -E "upgraded (linux|systemd|dbus|wayland|hyprland|mesa|glibc)" | tail -n 10)
if [ -n "$last_upgrade_logs" ]; then
    reboot_needed=true
    echo "⚠️  Se actualizaron paquetes críticos recientemente:"
    echo "$last_upgrade_logs"
fi

if [ "$reboot_needed" = true ]; then
    echo
    echo "========================================================"
    echo "  ⚠️  RECOMENDADO: Reinicie su equipo para aplicar"
    echo "      los cambios del kernel o paquetes críticos."
    echo "========================================================"
else
    echo
    echo "========================================================"
    echo "  ✅  Actualización completada. No es necesario reiniciar."
    echo "========================================================"
fi

# Guardar registro persistente de actualización (reinicia el ciclo semanal)
mkdir -p "$HOME/.local/state/quickshell/updater"
date +%Y-%m-%d > "$HOME/.local/state/quickshell/updater/last_update_date"
date +%Y-%m-%d > "$HOME/.local/state/quickshell/updater/last_check_date"
date +%s > "$HOME/.local/state/quickshell/updater/last_check_timestamp"

# Notificar a Quickshell borrando los flags de actualizaciones pendientes
rm -f "$HOME/.cache/quickshell/updater/update_pending"
rm -f "$HOME/.cache/quickshell/updater/notified_count"
rm -f "$HOME/.cache/quickshell/updater/updates_summary.txt"

echo
echo "Presione cualquier tecla para cerrar esta ventana..."
read -n 1 -s -r
