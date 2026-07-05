# Dotfiles de Hyprland (JD)

Este repositorio contiene las configuraciones completas de mi entorno gráfico Hyprland para dos perfiles distintos.

---

## 📂 Estructura del Repositorio

* **`setup-ilyamiro/`**: Mi configuración activa y moderna.
  * **Compositor**: Hyprland
  * **Widget Shell / Barra**: Quickshell (QML/JS)
  * **Barra lateral de uso de sistema**: Bloque flotante fijado a la pantalla secundaria (`DP-2`) con monitorización simétrica de CPU, RAM, GPU (Radeon RX 6600), velocidades de Red, temperaturas y estado de discos.
  * **Gestor de Actualizaciones**: Botón persistente en la barra superior con un panel emergente dual para realizar copias de seguridad/actualizaciones de dotfiles y mantenimiento completo del sistema (pacman, AUR, Flatpak y limpieza de huérfanos).
* **`setup-end4/`**: Mi configuración clásica de respaldo.
* **`setup_stow_profiles.sh`**: Script para alternar los perfiles de configuración utilizando GNU Stow.

---

## 🔄 Respaldos y Actualizaciones Automáticas

Las actualizaciones del sistema y de los archivos de configuración (dotfiles) se gestionan de manera visual directamente desde el panel de Quickshell.

### 🟢 Respaldo de Dotfiles (`DOTS UPDATE`)
Al activar este botón en el panel de actualizaciones:
1. Se realiza un escaneo de cambios en toda la carpeta `~/dotfiles`.
2. Se genera un commit automático con marca de tiempo: `Respaldo automático: YYYY-MM-DD HH:MM:SS`.
3. Se suben los cambios (push) a mi repositorio personal en GitHub: `git@github.com:JuanDiego360/DotfileHyprlandJD.git`.
4. Se descargan e integran (pull) los cambios remotos.

### 🔵 Actualización del Sistema (`SYSTEM UPDATE`)
Al activar este botón, se abre una terminal interactiva que realiza:
1. Actualización de repositorios oficiales y AUR utilizando `yay -Syu`.
2. Actualización de paquetes de Flatpak.
3. Tareas de limpieza de archivos huérfanos (`pacman -Rns $(pacman -Qtdq)`) y dependencias innecesarias de yay.
4. Limpieza automática de la caché de paquetes y remoción de runtimes Flatpak sin uso.
5. Diagnóstico inteligente del kernel para recomendar el reinicio del equipo en caso de ser necesario.
