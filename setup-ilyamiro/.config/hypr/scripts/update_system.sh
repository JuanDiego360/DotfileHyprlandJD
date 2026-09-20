#!/usr/bin/env bash

# Clear terminal screen
clear

echo "========================================================"
echo "   ACTUALIZACIÓN COMPLETA DEL SISTEMA Y LIMPIEZA (CachyOS)"
echo "========================================================"
echo

# Variables de entorno para compilación de paquetes Rust/Cargo desde AUR
export CARGO_NET_GIT_FETCH_WITH_CLI=true

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
