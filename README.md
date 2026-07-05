# Dotfiles de Hyprland (JD)

Este repositorio contiene las configuraciones completas de mi entorno gráfico Hyprland, estructuradas y administradas mediante GNU Stow para alternar fácilmente entre perfiles.

---

## 📂 Estructura del Repositorio

* **`setup-ilyamiro/`**: Mi configuración activa y moderna.
  * **Compositor**: Hyprland
  * **Widget Shell / Barra**: Quickshell (QML/JS)
  * **Barra lateral de uso de sistema**: Bloque flotante en la pantalla secundaria (`DP-2`) con monitoreo simétrico de CPU, RAM, GPU (Radeon RX 6600), velocidades de Red, temperaturas y estado de discos.
  * **Gestor de Actualizaciones**: Botón en la barra superior con panel emergente dual para actualizar dotfiles y paquetes del sistema (pacman, AUR, Flatpak y limpieza de huérfanos).
* **`setup-end4/`**: Mi configuración clásica de respaldo (basada en Lua).
* **`setup_stow_profiles.sh`**: Script para migrar, respaldar y estructurar las configuraciones iniciales.

---

## ⚙️ Cómo cambiar de perfil con GNU Stow

GNU Stow crea enlaces simbólicos (**symlinks**) desde el repositorio hacia tu carpeta `~/.config/`.

### 🔄 Paso 1: Inicialización (Solo la primera vez)
Si estás migrando tu configuración por primera vez, ejecuta el script de migración para estructurar tu perfil original `end-4` dentro del repositorio:
```bash
bash ~/dotfiles/setup_stow_profiles.sh
```
*Esto moverá tus carpetas actuales `hypr`, `cava` y `matugen` hacia `~/dotfiles/setup-end4/` y creará copias `.bak-stow` en `~/.config/` por seguridad.*

### 🔵 Activar el perfil de Quickshell (ilyamiro)
Para desactivar la configuración anterior y enlazar la nueva:
```bash
cd ~/dotfiles
stow -D setup-end4        # Desvincula el perfil antiguo
stow -v setup-ilyamiro    # Enlaza el perfil nuevo
```

### 🔴 Volver al perfil clásico (end-4)
Para regresar a tu entorno anterior en cualquier momento:
```bash
cd ~/dotfiles
stow -D setup-ilyamiro    # Desvincula el perfil nuevo
stow -v setup-end4        # Enlaza el perfil antiguo
```

### 🛠️ Compilación de Plantillas (Obligatorio en primer inicio de ilyamiro)
La primera vez que actives el perfil de `ilyamiro`, compila las plantillas del watch settings para generar tu archivo de entorno y variables de sistema:
```bash
bash ~/.config/hypr/scripts/settings_watcher.sh --compile
```

---

## 🔄 Respaldos y Actualizaciones Automáticas

### 🟢 Respaldo de Dotfiles (`DOTS UPDATE`)
Al activar este botón en el panel de actualizaciones:
1. Se realiza un escaneo de cambios en toda la carpeta `~/dotfiles` (ambos perfiles).
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

---

## 🚀 Guía de Instalación desde cero (Replicabilidad)

Si necesitas instalar este entorno en una máquina limpia o un nuevo usuario:

### 📦 1. Instalar dependencias del sistema (Arch / CachyOS)
Asegura que tu sistema tenga instaladas las herramientas globales de Qt6, QML y compiladores:
```bash
sudo pacman -S --needed git stow kitty wezterm qt6-5compat qt6-multimedia qt6-svg
```

Instala los componentes críticos desde AUR:
```bash
yay -S --needed quickshell-git matugen-bin swayosd-git
```

### 📥 2. Clonar e inicializar el repositorio
Clona el repositorio en la carpeta `~/dotfiles` de tu home:
```bash
git clone git@github.com:JuanDiego360/DotfileHyprlandJD.git ~/dotfiles
cd ~/dotfiles
```

### 🔗 3. Enlazar las carpetas de configuración
Aplica el enlace simbólico del perfil `ilyamiro` usando GNU Stow:
```bash
stow -v setup-ilyamiro
```

### ⚙️ 4. Generar archivos de variables locales
Genera la base de datos de configuraciones locales de Hyprland compilando las plantillas de Matugen:
```bash
bash ~/.config/hypr/scripts/settings_watcher.sh --compile
```

Finalmente, recarga Hyprland (`hyprctl reload`) o reinicia tu sesión de usuario para disfrutar del entorno completo.

---

## ⌨️ Cheat-Sheet de Atajos de Teclado (ilyamiro)

Mapeos personalizados de teclas configurados en `keybindings.conf`:

| Acción | Combinación |
| :--- | :--- |
| **Cerrar Ventana Activa** | `SUPER + Q` o `ALT + F4` |
| **Float/Tile Inteligente (500x350)** | `SUPER + ALT + code:64` |
| **Captura de pantalla (Región)** | `SUPER + SHIFT + S` |
| **Filtro Relajante (Verde Oliva)** | `SUPER + SHIFT + G` |
| **Modo Juego (Desactiva efectos)** | `SUPER + ALT + G` |
| **Scratchpad (Toggle / Enviar)** | `SUPER + S` / `SUPER + ALT + S` |
| **Workspace (Navegar / Enviar)** | `SUPER + <1..0>` / `SUPER + SHIFT + <1..0>` |
| **Mostrar Música** | `SUPER + M` |
| **Seleccionar Fondo (Wallpaper)** | `CTRL + SUPER + T` |
| **Mostrar Calendario** | `SUPER + ALT + C` |
| **Centro de Uso de Sistema (Panel)** | `SUPER + U` (fijo en monitor `DP-2`) |
| **Historial de Portapapeles** | `SUPER + V` |
| **Control de Volumen** | `SUPER + ALT + V` |
| **Lanzador de Aplicaciones** | `SUPER + Space` |
| **Centro de Ajustes** | `SUPER + I` |
| **Guía Rápida / Cheatsheet** | `SUPER + Slash` |
