-- Archivo de ejecuciones personalizadas
-- Aquí puedes añadir comandos que quieres que se ejecuten al iniciar Hyprland

hl.on("hyprland.start", function()
    -- Aplicar reglas de ventana para Steam de forma directa
    -- Usamos dispatch para intentar forzar el comportamiento si keyword falla
    hl.exec_cmd("hyprctl keyword windowrulev2 'monitor HDMI-A-1, class:^(steam_app_.*)$'")
    hl.exec_cmd("hyprctl keyword windowrulev2 'workspace 1, class:^(steam_app_.*)$'")
    hl.exec_cmd("hyprctl keyword windowrulev2 'fullscreen 1, class:^(steam_app_.*)$'")
end)
