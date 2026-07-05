#!/usr/bin/env bash

# Clear terminal screen
clear

echo "========================================================"
echo "   ACTUALIZACIÓN COMPLETA DEL SISTEMA Y LIMPIEZA"
echo "========================================================"
echo

# 1. Actualización de Repositorios oficiales y AUR
echo "--> 1. Buscando y aplicando actualizaciones de Pacman y AUR con 'yay'..."
yay -Syu

# 2. Actualización de Flatpak
if command -v flatpak &> /dev/null; then
    echo
    echo "--> 2. Buscando y aplicando actualizaciones de Flatpak..."
    flatpak update -y
fi

# 3. Limpieza del sistema
echo
echo "--> 3. Realizando tareas de limpieza..."

# Huérfanos de pacman
orphans=$(pacman -Qtdq)
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
    yay -Yc --noconfirm
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
    flatpak uninstall --unused -y
fi

# 4. Comprobación de reinicio
echo
echo "--> 4. Comprobando si es necesario reiniciar el sistema..."
reboot_needed=false
running_kernel=$(uname -r)

if [ ! -d "/usr/lib/modules/$running_kernel" ]; then
    reboot_needed=true
    echo "⚠️  ¡El kernel ha sido actualizado! (Kernel ejecutándose: $running_kernel no existe en /usr/lib/modules)"
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

# Notificar a Quickshell borrando el flag de actualizaciones pendientes
rm -f "$HOME/.cache/quickshell/updater/update_pending"

echo "Presione cualquier tecla para cerrar esta ventana..."
read -n 1 -s -r
