#!/usr/bin/env bash

# Clear terminal screen
clear

echo "========================================================"
echo "   ACTUALIZACIÓN COMPLETA DEL SISTEMA Y LIMPIEZA"
echo "========================================================"
echo

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

# Notificar a Quickshell para vaciar el contador de actualizaciones inmediatamente
if command -v quickshell &> /dev/null; then
    quickshell ipc -c ii call updates clear &> /dev/null || true
fi

echo "Presione cualquier tecla para cerrar esta ventana..."
read -n 1 -s -r
