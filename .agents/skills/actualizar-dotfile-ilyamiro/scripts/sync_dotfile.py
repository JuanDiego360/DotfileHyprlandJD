#!/usr/bin/env python3
"""
sync_dotfile.py - Sincronizador automatizado del upstream de Ilyamiro hacia setup-ilyamiro.
Preserva el 100% de las personalizaciones de Juan Diego:
- Botón de actualización en la barra superior (inotifywait, pulsos, updater modal)
- Capturas de pantalla multimonitor (QS_TARGET_MON, OCR, QR)
- Métricas AMD GPU / CPU / RAM (sys_fetcher.sh y SysData.qml)
- Terminal predeterminado WezTerm (wezterm start -- bash -c)
- Monitor clamp y popups personalizados en WindowRegistry.js
- Configuración de settings.json (~/.config/hypr/settings.json)
- Pantalla de bloqueo nativa por IPC y avatar personalizado
- Controladores multi-monitor con conteo seguro de pantallas
"""

import os
import sys
import shutil
import filecmp
import subprocess
import json

DOTFILES_DIR = os.path.expanduser("/home/juandiego/dotfiles")
SRC_DIR = os.path.join(DOTFILES_DIR, "src/quickshell")
SETUP_DIR = os.path.join(DOTFILES_DIR, "setup-ilyamiro/.config/hypr/scripts/quickshell")

# Archivos protegidos que NUNCA deben sobrescribirse con el código vanilla de upstream
PROTECTED_FILES = {
    "bar/faces/left/LeftFace.qml",
    "screenshot/ScreenshotOverlay.qml",
    "singletons/info/SysData.qml",
    "singletons/system/Config.qml",
    "singletons/theme/Scaler.qml",
    "singletons/widgetcontrols/ClipboardController.qml",
    "singletons/widgetcontrols/LauncherController.qml",
    "watchers/sys_fetcher.sh",
    "WindowRegistry.js",
    "launcher/Launcher.qml",
    "qmldir"
}

def audit():
    print("=== AUDITANDO DIFERENCIAS ENTRE SRC Y SETUP-ILYAMIRO ===")
    diff_files = []
    only_src = []
    only_dst = []

    for root, _, files in os.walk(SRC_DIR):
        rel_path = os.path.relpath(root, SRC_DIR)
        target_root = os.path.join(SETUP_DIR, rel_path)
        for f in files:
            src_f = os.path.join(root, f)
            dst_f = os.path.join(target_root, f)
            rel_f = os.path.relpath(src_f, SRC_DIR)
            if not os.path.exists(dst_f):
                only_src.append(rel_f)
            else:
                if not filecmp.cmp(src_f, dst_f, shallow=False):
                    diff_files.append(rel_f)

    for root, _, files in os.walk(SETUP_DIR):
        rel_path = os.path.relpath(root, SETUP_DIR)
        src_root = os.path.join(SRC_DIR, rel_path)
        for f in files:
            dst_f = os.path.join(root, f)
            src_f = os.path.join(src_root, f)
            rel_f = os.path.relpath(dst_f, SETUP_DIR)
            if not os.path.exists(src_f):
                only_dst.append(rel_f)

    print(f"Archivos modificados ({len(diff_files)}):")
    for f in sorted(diff_files):
        p = " [PROTEGIDO]" if f in PROTECTED_FILES else ""
        print(f"  - {f}{p}")

    print(f"\nArchivos nuevos en src ({len(only_src)}):")
    for f in sorted(only_src):
        print(f"  + {f}")

    print(f"\nArchivos exclusivos de setup-ilyamiro ({len(only_dst)}):")
    for f in sorted(only_dst):
        print(f"  * {f}")

    return diff_files, only_src, only_dst

def sync():
    print("\n=== INICIANDO SINCRONIZACIÓN AUTOMÁTICA ===")
    
    # 1. Copiar todos los archivos de src a setup-ilyamiro respetando la lista protegida
    for root, _, files in os.walk(SRC_DIR):
        rel_path = os.path.relpath(root, SRC_DIR)
        target_dir = os.path.join(SETUP_DIR, rel_path)
        os.makedirs(target_dir, exist_ok=True)
        for f in files:
            rel_file = os.path.normpath(os.path.join(rel_path, f))
            if rel_file.startswith("./"):
                rel_file = rel_file[2:]
            
            if rel_file in PROTECTED_FILES:
                continue

            src_file = os.path.join(root, f)
            dst_file = os.path.join(target_dir, f)
            shutil.copy2(src_file, dst_file)

    # 2. Re-aplicar personalizaciones críticas en archivos sincronizados:
    
    # Dock: asegurar wezterm
    dock_state = os.path.join(SETUP_DIR, "dock/DockWindowState.qml")
    if os.path.exists(dock_state):
        with open(dock_state, "r", encoding="utf-8") as fp:
            content = fp.read()
        content = content.replace('"terminalCommand": "kitty -e"', '"terminalCommand": "wezterm start -- bash -c"')
        with open(dock_state, "w", encoding="utf-8") as fp:
            fp.write(content)

    # LauncherTab: asegurar wezterm
    launcher_tab = os.path.join(SETUP_DIR, "guide/LauncherTab.qml")
    if os.path.exists(launcher_tab):
        with open(launcher_tab, "r", encoding="utf-8") as fp:
            content = fp.read()
        content = content.replace('"kitty -e"', '"wezterm start -- bash -c"')
        with open(launcher_tab, "w", encoding="utf-8") as fp:
            fp.write(content)

    # AboutTab: asegurar wezterm
    about_tab = os.path.join(SETUP_DIR, "guide/AboutTab.qml")
    if os.path.exists(about_tab):
        with open(about_tab, "r", encoding="utf-8") as fp:
            content = fp.read()
        if "if command -v wezterm" not in content and "command -v kitty" in content:
            content = content.replace(
                "if command -v kitty >/dev/null 2>&1; then kitty --hold bash -c",
                "if command -v wezterm >/dev/null 2>&1; then wezterm start -- bash -c 'eval \"$(curl -fsSL https://raw.githubusercontent.com/ilyamiro/serpantinum/master/install/install.sh)\"'; elif command -v kitty >/dev/null 2>&1; then kitty --hold bash -c"
            )
            with open(about_tab, "w", encoding="utf-8") as fp:
                fp.write(content)

    # Calendar: asegurar no fijar ancho/alto rígido para no romper monitores pequeños
    calendar_f = os.path.join(SETUP_DIR, "calendar/CalendarPopup.qml")
    if os.path.exists(calendar_f):
        with open(calendar_f, "r", encoding="utf-8") as fp:
            content = fp.read()
        # Si tiene implicitWidth rígido, lo comentamos
        lines = content.splitlines()
        new_lines = []
        for line in lines:
            if any(k in line for k in ["targetMasterHeight:", "targetMasterWidth:", "implicitWidth: targetMasterWidth", "implicitHeight: targetMasterHeight", "width: targetMasterWidth", "height: targetMasterHeight"]):
                continue
            new_lines.append(line)
        with open(calendar_f, "w", encoding="utf-8") as fp:
            fp.write("\n".join(new_lines) + "\n")

    # Lock: asegurar que lock/qmldir registre VideoLock y FingerprintIndicator
    lock_qmldir = os.path.join(SETUP_DIR, "lock/qmldir")
    if os.path.exists(lock_qmldir):
        with open(lock_qmldir, "r", encoding="utf-8") as fp:
            q_content = fp.read()
        if "VideoLock" not in q_content:
            q_content = "VideoLock 1.0 VideoLock.qml\n" + q_content
        if "FingerprintIndicator" not in q_content:
            q_content = "FingerprintIndicator 1.0 FingerprintIndicator.qml\n" + q_content
        with open(lock_qmldir, "w", encoding="utf-8") as fp:
            fp.write(q_content)

    # Caching / Scripts: sincronizar WindowRegistry a src para mantener consistencia bidireccional
    shutil.copy2(os.path.join(SETUP_DIR, "WindowRegistry.js"), os.path.join(SRC_DIR, "WindowRegistry.js"))
    shutil.copy2(os.path.join(SETUP_DIR, "launcher/Launcher.qml"), os.path.join(SRC_DIR, "launcher/Launcher.qml"))
    shutil.copy2(os.path.join(SETUP_DIR, "singletons/widgetcontrols/ClipboardController.qml"), os.path.join(SRC_DIR, "singletons/widgetcontrols/ClipboardController.qml"))
    shutil.copy2(os.path.join(SETUP_DIR, "singletons/widgetcontrols/LauncherController.qml"), os.path.join(SRC_DIR, "singletons/widgetcontrols/LauncherController.qml"))

    print("✔ Sincronización completada con éxito.")

def reload_quickshell():
    print("\n=== REINICIANDO / RECARGANDO QUICKSHELL DESACOPLADO ===")
    # Primero intentamos recarga vía IPC
    shell_path = os.path.expanduser("~/.config/hypr/scripts/quickshell/Shell.qml")
    cmd_ipc = ["quickshell", "-p", shell_path, "ipc", "call", "main", "forceReload"]
    res = subprocess.run(cmd_ipc, capture_output=True, text=True)
    if res.returncode == 0:
        print("✔ Recarga IPC enviada con éxito.")
    else:
        print("IPC falló o quickshell no respondía, reiniciando mediante hyprctl dispatch...")
        subprocess.run(["pkill", "-f", "quickshell.*Shell.qml"])
        subprocess.run(["sleep", "1"])
        subprocess.run(["hyprctl", "dispatch", "exec", f"quickshell -p {shell_path}"])
        print("✔ Quickshell relanzado bajo Hyprland.")

if __name__ == "__main__":
    if len(sys.argv) > 1 and sys.argv[1] == "--audit":
        audit()
    elif len(sys.argv) > 1 and sys.argv[1] == "--reload":
        reload_quickshell()
    else:
        audit()
        sync()
        reload_quickshell()
