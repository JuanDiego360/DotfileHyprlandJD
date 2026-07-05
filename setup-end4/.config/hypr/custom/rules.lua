-- ####################################################
-- Gaming Rules: Steam + Proton en HDMI-A-1 (TV grande)
-- Modo juego toggle: archivo /tmp/game-mode-lock.state
-- ####################################################

-- Detectar si el modo juego está activo
local game_lock_file = io.open("/tmp/game-mode-lock.state")
local game_mode = game_lock_file ~= nil
if game_lock_file then game_lock_file:close() end

-- Forzar juegos de Steam al monitor HDMI-A-1
hl.window_rule({ match = { class = "^(steam_app).*" }, monitor = "HDMI-A-1" })
-- Marcar como contenido tipo "game" (optimiza VRR y rendimiento)
hl.window_rule({ match = { class = "^(steam_app).*" }, content = "game" })
-- Fullscreen automático
hl.window_rule({ match = { class = "^(steam_app).*" }, fullscreen = true })
-- Eliminar límites de tamaño máximo (juegos que cambian resolución)
hl.window_rule({ match = { class = "^(steam_app).*" }, no_max_size = true })
-- Sin sombra para mejor rendimiento en fullscreen
hl.window_rule({ match = { class = "^(steam_app).*" }, no_shadow = true })
-- Sin blur para mejor rendimiento
hl.window_rule({ match = { class = "^(steam_app).*" }, no_blur = true })
-- Tearing permitido
hl.window_rule({ match = { class = "^(steam_app).*" }, immediate = true })

-- stay_focused: solo si el modo juego está activo
if game_mode then
    hl.window_rule({ match = { class = "^(steam_app).*" }, stay_focused = true })
end

-- También cubrir juegos por título (comodín .exe para Proton)
local exe_rule = { match = { title = ".*\\.exe" }, monitor = "HDMI-A-1", content = "game", fullscreen = true, no_max_size = true, no_shadow = true, no_blur = true, immediate = true }
if game_mode then
    exe_rule.stay_focused = true
end
hl.window_rule(exe_rule)

-- Minecraft (por título)
local mc_rule = { match = { title = ".*minecraft.*" }, monitor = "HDMI-A-1", content = "game", fullscreen = true, no_max_size = true, immediate = true }
if game_mode then
    mc_rule.stay_focused = true
end
hl.window_rule(mc_rule)

-- Steam Big Picture
hl.window_rule({ match = { class = "^(steam)$", title = ".*Steam Big Picture.*" }, monitor = "HDMI-A-1", fullscreen = true })

-- Reglas para Satty: abrir flotante, centrado y a tamaño reducido (75% del monitor)
hl.window_rule({ match = { class = "^(com\\.gabm\\.satty)$" }, float = true })
hl.window_rule({ match = { class = "^(com\\.gabm\\.satty)$" }, center = true })
hl.window_rule({ match = { class = "^(com\\.gabm\\.satty)$" }, size = {"(monitor_w*0.75)", "(monitor_h*0.75)"} })

-- Reglas para WezTerm: permitir blur para fondos traslúcidos
hl.window_rule({ match = { class = "^(wezterm|org\\.wezfurlong%.wezterm)$" }, no_blur = false })

