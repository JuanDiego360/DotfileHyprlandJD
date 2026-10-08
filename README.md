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

<br><br><br>

<div align="center">
  <h3>Thanks to all contributors</h3>
  <br>

  <a href="https://github.com/TheRinder2"><img src="https://avatars.githubusercontent.com/u/48689803?v=4&s=48" width="48" height="48" alt="TheRinder2"></a>
  <a href="https://github.com/bizneskind-droid"><img src="https://avatars.githubusercontent.com/u/245046997?v=4&s=48" width="48" height="48" alt="bizneskind-droid"></a>
  <a href="https://github.com/Pigeon78"><img src="https://avatars.githubusercontent.com/u/151051379?v=4&s=48" width="48" height="48" alt="Pigeon78"></a>
  <a href="https://github.com/Eduarduar"><img src="https://avatars.githubusercontent.com/u/104547727?v=4&s=48" width="48" height="48" alt="Eduarduar"></a>
  <a href="https://github.com/Spinty-dev"><img src="https://avatars.githubusercontent.com/u/123001216?v=4&s=48" width="48" height="48" alt="Spinty-dev"></a>
  <a href="https://github.com/MrDexstor"><img src="https://avatars.githubusercontent.com/u/97257847?v=4&s=48" width="48" height="48" alt="MrDexstor"></a>
  <a href="https://github.com/coloramamoe"><img src="https://avatars.githubusercontent.com/u/117035740?v=4&s=48" width="48" height="48" alt="coloramamoe"></a>
  <a href="https://github.com/Zyxilon"><img src="https://avatars.githubusercontent.com/u/234867627?v=4&s=48" width="48" height="48" alt="Zyxilon"></a>
  <a href="https://github.com/gouthamkrishnap"><img src="https://avatars.githubusercontent.com/u/224089015?v=4&s=48" width="48" height="48" alt="gouthamkrishnap"></a>
  <a href="https://github.com/Stoltembergg"><img src="https://avatars.githubusercontent.com/u/312632452?v=4&s=48" width="48" height="48" alt="Stoltembergg"></a>
  <a href="https://github.com/andckadir"><img src="https://avatars.githubusercontent.com/u/175446585?v=4&s=48" width="48" height="48" alt="andckadir"></a>
  <a href="https://github.com/ArseniiTkachuk"><img src="https://avatars.githubusercontent.com/u/257102547?v=4&s=48" width="48" height="48" alt="ArseniiTkachuk"></a>
  <a href="https://github.com/MCUxDaredevil"><img src="https://avatars.githubusercontent.com/u/59441946?v=4&s=48" width="48" height="48" alt="MCUxDaredevil"></a>
  <a href="https://github.com/MILKv2"><img src="https://avatars.githubusercontent.com/u/142674287?v=4&s=48" width="48" height="48" alt="MILKv2"></a>
  <a href="https://github.com/pedrolourencosilva"><img src="https://avatars.githubusercontent.com/u/184855780?v=4&s=48" width="48" height="48" alt="pedrolourencosilva"></a>
  <a href="https://github.com/Vaspyyy"><img src="https://avatars.githubusercontent.com/u/197029450?v=4&s=48" width="48" height="48" alt="Vaspyyy"></a>
  <a href="https://github.com/Sergi122"><img src="https://avatars.githubusercontent.com/u/171693999?v=4&s=48" width="48" height="48" alt="Sergi122"></a>
  <a href="https://github.com/Syrup5845"><img src="https://avatars.githubusercontent.com/u/310795939?v=4&s=48" width="48" height="48" alt="Syrup5845"></a>
  <a href="https://github.com/forteleaf"><img src="https://avatars.githubusercontent.com/u/14119264?v=4&s=48" width="48" height="48" alt="forteleaf"></a>
  <a href="https://github.com/kranks-uga"><img src="https://avatars.githubusercontent.com/u/179175113?v=4&s=48" width="48" height="48" alt="kranks-uga"></a>
  <a href="https://github.com/zynx-real"><img src="https://avatars.githubusercontent.com/u/320626542?v=4&s=48" width="48" height="48" alt="zynx-real"></a>
</div>

<br><br>

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
