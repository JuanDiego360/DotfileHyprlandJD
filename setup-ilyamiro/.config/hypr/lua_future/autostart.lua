hl.on("hyprland.start", function()
  hl.exec_cmd("systemctl --user start hyprpolkitagent")
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("hypridle")
  hl.exec_cmd("quickshell -p ~/.config/hypr/scripts/quickshell/Shell.qml")
  hl.exec_cmd("~/.config/hypr/scripts/quickshell/focustime/launch_daemon.sh")
  hl.exec_cmd("~/.config/hypr/scripts/init.sh")
  hl.exec_cmd("~/.config/hypr/scripts/settings_watcher.sh &")
  hl.exec_cmd("playerctld")
  # SwayOSD disabled — Quickshell's OsdController.qml provides unified OSD for
  # volume, brightness, Caps Lock, Num Lock, mute, airplane mode with the shell's
  # theme. Keeping swayosd-server would cause double notifications (SwayOSD +
  # Quickshell) every time Caps Lock or Num Lock toggles.
  # hl.exec_cmd("swayosd-server --top-margin 0.9 --style \"$HOME/.config/swayosd/style.css\"")
  hl.exec_cmd("wl-paste --type text --watch cliphist store")
  hl.exec_cmd("wl-paste --type image --watch cliphist store")
  hl.exec_cmd("~/.config/hypr/scripts/volume_listener.sh")
  hl.exec_cmd("~/.config/hypr/scripts/update_notifier.sh")
  hl.exec_cmd("bash -c 'sleep 1 && ~/.config/hypr/scripts/qs_manager.sh toggle guide'")
end)
