-- Enviar ventana al workspace con SUPER+SHIFT+número
local f = io.open("/tmp/hypr-custom-keybinds.log", "w")
if f then
    f:write("terminal: " .. tostring(terminal) .. "\n")
    f:close()
end

-- (sobrescribe el comportamiento: antes era SUPER+ALT+número)
for i = 1, 10 do
    local numberkey = {10,11,12,13,14,15,16,17,18,19}
    hl.bind("SUPER + SHIFT + code:"..numberkey[i], hl.dsp.window.move({ workspace = i, follow = false}) )
end

-- Activar/Desactivar el filtro verde oliva relajante usando la API de Lua
hl.bind("SUPER + SHIFT + G", function()
    local current = hl.get_config("decoration:screen_shader")
    local shaderPath = "/home/juandiego/.config/hypr/shaders/olive_green.glsl"
    
    if current == shaderPath then
        hl.config({decoration = {screen_shader = "[[EMPTY]]"}})
        hl.exec_cmd("notify-send 'Filtro Verde Oliva' 'Desactivado' -a 'Hyprland'")
    else
        hl.config({decoration = {screen_shader = shaderPath}})
        hl.exec_cmd("notify-send 'Filtro Verde Oliva' 'Activado' -a 'Hyprland'")
    end
end)

-- Cambiar el sentido de la división (horizontal/vertical)
hl.bind("SUPER + H", hl.dsp.layout("togglesplit"), {description = "Cambiar sentido del split"})

-- Flotar/Tilear ventana con keycode 57 (Space) en vez del nombre "Space"
-- (el nombre "Space" no funciona bien con layout latam por alguna razón)
-- Desactivar el binding original por nombre "Space" (no funciona con layout latam)
hl.unbind("SUPER + ALT + Space")

-- Float/Tile inteligente: al flotar centra y redimensiona pequeño (deja espacio para ver apps detrás)
hl.bind("SUPER + ALT + code:64", function()
    hl.dispatch(hl.dsp.window.float({ action = "toggle" }))
    hl.dispatch(hl.dsp.window.center())
    hl.dispatch(hl.dsp.window.resize({ x = 500, y = 350 }))
end, { description = "Flotar (pequeño centrado) / Tilear ventana" })

-- Toggle modo juego: bloquea/libera el mouse al monitor del juego
hl.bind("SUPER + ALT + G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle-game-mode.sh"), { description = "Toggle Modo Juego (lock mouse)" })

-- Desactivar el atajo por defecto de captura de región
hl.unbind("SUPER + SHIFT + S")

-- Captura de pantalla de región con Satty (edición/anotación)
hl.bind("SUPER + SHIFT + S", hl.dsp.exec_cmd("grim -g \"$(slurp)\" - | satty --filename -"), { description = "Captura de región con Satty" })

