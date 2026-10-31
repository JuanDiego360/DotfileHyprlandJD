local mainMod = _G.mainMod or "SUPER"
local terminal = _G.terminal or "wezterm"

-- ───────── Mouse & Gestures ─────────
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-- ───────── Window Management ─────────
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind("ALT + F4", hl.dsp.window.close())
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen())
hl.bind("ALT + Tab", hl.dsp.window.cycle_next())
hl.bind(mainMod .. " + ALT + space", hl.dsp.exec_cmd('hyprctl --batch "dispatch togglefloating ; dispatch centerwindow ; dispatch resizeactive exact 500 350"'))
hl.bind(mainMod .. " + H", hl.dsp.layout("togglesplit"))

-- Focus window in direction:
hl.bind(mainMod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Move window in direction:
hl.bind(mainMod .. " + SHIFT + left", hl.dsp.window.move({ direction = "l" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.move({ direction = "r" }))
hl.bind(mainMod .. " + SHIFT + up", hl.dsp.window.move({ direction = "u" }))
hl.bind(mainMod .. " + SHIFT + down", hl.dsp.window.move({ direction = "d" }))

-- Resize window in direction:
hl.bind(mainMod .. " + CTRL + left", hl.dsp.window.resize({ x = -40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.resize({ x = 40, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + up", hl.dsp.window.resize({ x = 0, y = -40, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + down", hl.dsp.window.resize({ x = 0, y = 40, relative = true }), { repeating = true })

-- ───────── Applications & Launchers ─────────
hl.bind(mainMod .. " + Return", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + T", hl.dsp.exec_cmd(terminal))
hl.bind("CTRL + ALT + T", hl.dsp.exec_cmd(terminal))
hl.bind(mainMod .. " + W", hl.dsp.exec_cmd("zen-browser"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("dolphin"))
hl.bind(mainMod .. " + C", hl.dsp.exec_cmd("code"))

-- ───────── Quickshell Controls ─────────
hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/reload.sh"))
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle clipboard"))
hl.bind(mainMod .. " + P", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle movies"))
hl.bind(mainMod .. " + space", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle applauncher"))
hl.bind(mainMod .. " + I", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle settings"))
hl.bind(mainMod .. " + M", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle music"))
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle lyrics"))
hl.bind(mainMod .. " + B", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle battery"))
hl.bind(mainMod .. " + U", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle floating 1"))
hl.bind("CTRL + " .. mainMod .. " + T", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle wallpaper"))
hl.bind(mainMod .. " + ALT + C", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle calendar"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle network"))
hl.bind(mainMod .. " + SHIFT + T", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle focustime"))
hl.bind(mainMod .. " + ALT + V", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle volume"))
hl.bind(mainMod .. " + slash", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/qs_manager.sh toggle guide"))

-- ───────── System & Hardware ─────────
hl.bind("Caps_Lock", hl.dsp.exec_cmd("sleep 0.1 && swayosd-client --caps-lock"), { locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("swayosd-client --brightness lower"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("swayosd-client --brightness raise"), { locked = true })
hl.bind("Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"), { locked = true })
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --edit"), { locked = true })
hl.bind(mainMod .. " + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full"), { locked = true })
hl.bind(mainMod .. " + SHIFT + Print", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --full --edit"), { locked = true })
hl.bind("XF86PowerOff", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"), { locked = true })
hl.bind(mainMod .. " + L", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/lock.sh"), { repeating = true, locked = true })

-- ───────── Custom Extras ─────────
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind(mainMod .. " + SHIFT + O", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --ocr"))
hl.bind(mainMod .. " + ALT + R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screen_record.sh"))
hl.bind(mainMod .. " + D", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/screen_draw.sh"))
hl.bind(mainMod .. " + SHIFT + G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle-olive-shader.sh"))
hl.bind(mainMod .. " + ALT + G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle-game-mode.sh"))

-- ───────── Scratchpad ─────────
hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("special"))
hl.bind(mainMod .. " + ALT + S", hl.dsp.window.move({ workspace = "special:special", silent = true }))

-- ───────── Media & Audio ─────────
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("swayosd-client --input-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("swayosd-client --output-volume mute-toggle"), { locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("swayosd-client --output-volume lower"), { repeating = true, locked = true })
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("swayosd-client --output-volume raise"), { repeating = true, locked = true })

-- ───────── Workspaces ─────────
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh " .. i))
  hl.bind(mainMod .. " + SHIFT + " .. i, hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh " .. i .. " move_silent"))
end
hl.bind(mainMod .. " + 0", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh 10"))
hl.bind(mainMod .. " + SHIFT + 0", hl.dsp.exec_cmd("~/.config/hypr/scripts/qs_manager.sh 10 move_silent"))

hl.bind(mainMod .. " + Tab", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_next_monitor.sh"))
