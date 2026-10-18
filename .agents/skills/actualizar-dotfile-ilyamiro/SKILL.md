---
name: actualizar-dotfile-ilyamiro
description: >-
  Guía completa y procedimiento automatizado para sincronizar actualizaciones upstream de
  ilyamiro/nixos-configuration hacia el entorno activo setup-ilyamiro preservando el 100% de
  las personalizaciones locales (barra, actualizador, capturas de pantalla, GPU/CPU, wezterm,
  pantalla de bloqueo y escalado).
---

# Skill: Actualizar Dotfile de Ilyamiro (Preservando Personalizaciones)

Esta habilidad documenta y automatiza el flujo completo para actualizar el dotfile local (`/home/juandiego/dotfiles`) incorporando las novedades del repositorio upstream de **Ilyamiro** (`ilyamiro/nixos-configuration`) hacia la configuración activa del usuario (`setup-ilyamiro`), **sin romper ni perder ninguna de las personalizaciones desarrolladas en sesiones anteriores**.

---

## 1. Arquitectura del Repositorio

- **Repositorio local:** `/home/juandiego/dotfiles` (rama activa: `main`).
- **Remoto upstream:** `upstream` -> `https://github.com/ilyamiro/nixos-configuration.git`.
- **Estructura de carpetas:**
  - `src/quickshell/`: Contiene el código fuente que se actualiza al hacer `git pull` o `git merge upstream/master`.
  - `setup-ilyamiro/`: Contiene el **entorno real y activo** del usuario.
  - `~/.config/hypr` es un enlace simbólico (`symlink`) que apunta a `/home/juandiego/dotfiles/setup-ilyamiro/.config/hypr`.
  - Quickshell se ejecuta leyendo: `~/.config/hypr/scripts/quickshell/Shell.qml`.
- **Por qué `git pull` no actualiza la interfaz automáticamente:**
  - Cuando se descargan cambios con Git, Git actualiza `src/`.
  - La interfaz que está corriendo en pantalla proviene de `setup-ilyamiro/.config/hypr/scripts/quickshell/`.
  - Por tanto, se requiere una **sincronización selectiva** desde `src/quickshell/` hacia `setup-ilyamiro/.config/hypr/scripts/quickshell/`.

---

## 2. Lista Blanca de Personalizaciones (NUNCA Sobrescribir con Vanilla)

Antes de copiar o actualizar archivos, los agentes (Hermes y Antigravity) deben verificar y respetar esta lista:

| Componente / Archivo | Ubicación en `setup-ilyamiro` | Personalización crítica a preservar |
| :--- | :--- | :--- |
| **Botón de Actualizaciones** | `.../bar/faces/left/LeftFace.qml` | `updateBtn`, `updatePoller` (`inotifywait` sobre `/run/user/1000/serpantinum/updates_status`), efecto glow pulsante y apertura de `UpdaterPopup`. |
| **Scripts de Actualización** | `.../updater/UpdaterPopup.qml`<br>`.../scripts/update_*.sh` | Ventana de actualización modular, `update_notifier.sh` semanal, `update_system.sh` (pacman/paru) y `update_dots.sh`. |
| **Captura Multimonitor** | `.../screenshot/ScreenshotOverlay.qml`<br>`.../scripts/screenshot.sh` | Soporte multimonitor (`targetScreen`, variable `QS_TARGET_MON`), recorte en monitor enfocado (HDMI / DP-2), OCR y lector QR. |
| **Métricas Hardware (`SUPER + U`)** | `.../watchers/sys_fetcher.sh`<br>`.../singletons/info/SysData.qml` | Lectura de GPU AMD en `/sys/class/drm/card*` (`gpu_busy_percent`, temperatura), métrica real de RAM y temperaturas CPU `hwmon`. |
| **Terminal Predeterminado** | Múltiples archivos QML | Debe ser siempre `wezterm start -- bash -c` en lugar de `kitty -e`:<br>• `dock/DockWindowState.qml`<br>• `launcher/Launcher.qml`<br>• `guide/LauncherTab.qml`<br>• `guide/AboutTab.qml` |
| **Ruta de Configuración** | `.../singletons/system/Config.qml` | `settingsJsonPath` debe apuntar a `homeDir + "/.config/hypr/settings.json"` (NO a serpantinum). |
| **Escalado UI (Scaler)** | `.../singletons/theme/Scaler.qml` | Función de escalado: `function s(val) { return val * uiScale; }`. |
| **Registro de Ventanas y Clamping** | `.../WindowRegistry.js` | Popups registrados (`settings`, `productivity`, `focustime`, `movies`, `stewart`, `moon`, `lyrics`, `updater`, `battery`) y límite de tamaño `Math.min(finalW, mw - margin)` para evitar desbordes en monitores secundarios (1280x1024 y 1366x768). |
| **Lanzador de Aplicaciones** | `.../launcher/Launcher.qml` | Búsqueda por ejecutable y desktop_id (ej: encontrar pavucontrol al escribir pavucontrol) y captura de excepciones en `entry.execute()`. |
| **Pantalla de Bloqueo Nativa** | `.../scripts/lock.sh`<br>`.../hypridle.conf`<br>`.../lock/qmldir` | Enviar señal IPC nativa `quickshell -p $MAIN_QML ipc call lock activate`. Registrar `VideoLock` y `FingerprintIndicator` en `lock/qmldir`. |
| **Foto de Perfil (Avatar)** | `~/.config/hypr/settings.json`<br>`~/.cache/serpantinum/avatar/` | `general.avatarPath` enlazado a la imagen del usuario y copiado a `avatar_cropped.png`, `~/.face` y `~/.face.icon`. |
| **Controladores Seguros** | `.../widgetcontrols/ClipboardController.qml`<br>`.../widgetcontrols/LauncherController.qml` | Validación segura de `screens.length !== undefined ? screens.length : (screens.count !== undefined ? screens.count : 0)`. |
| **Servidor de Notificaciones** | `.../notifications/NotificationManager.qml` | Quickshell provee el servidor nativo de notificaciones (`org.freedesktop.Notifications`). Cualquier daemon externo (`swaync.service`) debe permanecer enmascarado (`systemctl --user mask swaync.service`) para no usurpar el bus. |

---

## 3. Procedimiento Paso a Paso de Actualización

Cuando el usuario solicite actualizar el dotfile o cuando se detecten nuevos commits en upstream:

### Paso 1: Descargar cambios de Git
```bash
cd /home/juandiego/dotfiles
git fetch upstream master
git merge upstream/master -m "Merge upstream de ilyamiro/nixos-configuration"
```

### Paso 2: Ejecutar el sincronizador automatizado
Se ha provisto un script Python automatizado en esta skill que realiza la auditoría y sincronización respetando la lista blanca:

```bash
python3 /home/juandiego/dotfiles/.agents/skills/actualizar-dotfile-ilyamiro/scripts/sync_dotfile.py
```
*(El script también se encuentra disponible en `~/.hermes/skills/software-development/actualizar-dotfile-ilyamiro/scripts/sync_dotfile.py`)*

### Paso 3: Opciones del sincronizador
- **Solo auditar sin modificar:**
  ```bash
  python3 /home/juandiego/dotfiles/.agents/skills/actualizar-dotfile-ilyamiro/scripts/sync_dotfile.py --audit
  ```
- **Solo recargar Quickshell:**
  ```bash
  python3 /home/juandiego/dotfiles/.agents/skills/actualizar-dotfile-ilyamiro/scripts/sync_dotfile.py --reload
  ```

### Paso 4: Regla de oro para el proceso de Quickshell
> [!IMPORTANT]
> **NUNCA ejecutes Quickshell amarrado al subshell o terminal del asistente.** Si el asistente se cierra, la barra y los widgets morirían.
> 
> Siempre recárgalo mediante IPC:
> ```bash
> quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml ipc call main forceReload
> ```
> O si necesitas reiniciarlo desde cero, hazlo desacoplado bajo Hyprland:
> ```bash
> pkill -f "quickshell.*Shell.qml" && sleep 1 && hyprctl dispatch exec "quickshell -p /home/juandiego/.config/hypr/scripts/quickshell/Shell.qml"
> ```

### Paso 5: Verificar que no haya errores
Revisar el registro de Quickshell:
```bash
quickshell log -p ~/.config/hypr/scripts/quickshell/Shell.qml -t 30
```
Debe mostrar `INFO: Configuration Loaded` sin excepciones críticas de sintaxis QML.

### Paso 6: Confirmar en Git
```bash
git add .
git commit -m "feat(update): sincronizar upstream preservando personalizaciones del usuario"
```

---

## 4. Resumen para Responder al Usuario

Tras completar la sincronización, presenta un resumen estructurado indicando:
1. Las novedades y mejoras técnicas que trajo la versión de upstream (ej. optimizaciones de shaders, correcciones de issues, nuevas opciones de tema).
2. La confirmación explícita de que todas las funciones personalizadas (botón de actualización, capturas multimonitor, métricas GPU/CPU, Wezterm, pantalla de bloqueo) siguen operativas y verificadas.
