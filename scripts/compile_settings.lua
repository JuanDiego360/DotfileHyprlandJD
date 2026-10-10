#!/usr/bin/env lua
-- compile_settings.lua - Genera los modulos .lua de Hyprland desde settings.json
--
-- Uso: compile_settings.lua <settings.json> <default_settings.json> <out_dir> <templates_dir>
-- Devuelve 0 si todo compiló y validó con luac -p; !=0 si falló.

local function read_file(path)
    local f, err = io.open(path, "r")
    if not f then error("no puedo abrir " .. path .. ": " .. tostring(err)) end
    local s = f:read("*a"); f:close(); return s
end

local function write_file(path, content)
    local f, err = io.open(path, "w")
    if not f then error("no puedo escribir " .. path .. ": " .. tostring(err)) end
    f:write(content); f:close()
end

local function shell_quote(s)
    -- Quote segura para bash single-quote
    return "'" .. s:gsub("'", [['"'"']]) .. "'"
end

local function jq(query, file)
    -- jq -> Lua: parseo nativo del JSON con un helper externo.
    -- Para no añadir dependencia, usamos una llamada a jq -r y leemos stdout.
    local p = io.popen("jq -r " .. shell_quote(query) .. " " .. shell_quote(file) .. " 2>/dev/null")
    if not p then return nil end
    local s = p:read("*a"); p:close()
    if s == nil or s == "" or s == "null" then return nil end
    -- jq añade \n final; chompeamos.
    s = s:gsub("\n+$", "")
    return s
end

-- Lua-safe quoting para strings literales (acepta newlines escapando con \n).
-- Usa string.format %q cuando es seguro; cae a [[...]] para shell quotes.
local function lua_quote(s)
    -- Si la cadena contiene comillas simples simples Y nada que rompa [[...]], usa long-bracket
    if not s:find("]]") then
        return "[[" .. s .. "]]"
    end
    -- Fallback: %q (escapa con \")
    return string.format("%q", s)
end

-- Conversión segura de string JSON a boolean Lua real
local function tobool(s, default)
    if s == nil then return default end
    if s == "true" then return true end
    if s == "false" then return false end
    return default
end
local function tonum(s, default)
    if s == nil then return default end
    local n = tonumber(s); if n then return n end
    return default
end
local function str(s, default)
    if s == nil or s == "" or s == "null" then return default end
    return s
end

-- gsub replacement strings interpretan %N como backref. Escapa los %.
local function escape_replacement(s)
    return (s:gsub("%%", "%%%%"))
end

-- Mapea un bind del JSON al equivalente hl.bind(...) en Lua.
-- Tabla de dispatchers soportados; el resto se emite como hl.dsp.exec_cmd.
local function translate_bind(b, mainMod)
    local mods = b.mods or ""
    -- $mainMod -> valor de la variable Lua
    mods = mods:gsub("%$mainMod", mainMod)
    -- SHIFT_L / CTRL_L / ALT_L -> versión neutra (Hyprland acepta ambas)
    mods = mods:gsub("_L", "")
    mods = mods:gsub("_R", "")
    local key  = b.key or ""
    local disp = b.dispatcher or "exec"
    local cmd  = b.command or ""

    local combo = mods .. " + " .. key
    combo = combo:gsub("^%s+", ""):gsub("%s+$", "")

    -- dispatchers conocidos -> helpers de la API Lua
    if disp == "exec" then
        return string.format('hl.bind(%q, hl.dsp.exec_cmd(%q), { locked = %s })',
            combo, cmd, b.locked == "true" and "true" or "false")
    elseif disp == "killactive" then
        return string.format('hl.bind(%q, hl.dsp.window.close())', combo)
    elseif disp == "togglefloating" then
        return string.format('hl.bind(%q, hl.dsp.window.float({ action = "toggle" }))', combo)
    elseif disp == "fullscreen" then
        return string.format('hl.bind(%q, hl.dsp.window.fullscreen({ mode = 1 }))', combo)
    elseif disp == "cyclenext" then
        return string.format('hl.bind(%q, hl.dsp.window.cycle({ next = true }))', combo)
    elseif disp == "bringactivetotop" then
        return string.format('hl.bind(%q, hl.dsp.window.bring_to_top())', combo)
    elseif disp == "movefocus" then
        return string.format('hl.bind(%q, hl.dsp.focus({ direction = %q }))', combo, cmd)
    elseif disp == "movewindow" then
        return string.format('hl.bind(%q, hl.dsp.window.move({ direction = %q }))', combo, cmd)
    elseif disp == "resizeactive" then
        return string.format('hl.bind(%q, hl.dsp.window.resize({ x = %s, y = %s, relative = true }), { repeating = true })',
            combo, tostring(tonumber((cmd:match("(%-?%d+)")) or 0)),
                       tostring(tonumber((cmd:match("%s(%-?%d+)")) or 0)))
    elseif disp == "togglesplit" then
        return string.format('hl.bind(%q, hl.dsp.layoutmsg("togglesplit"))', combo)
    elseif disp == "togglespecialworkspace" then
        return string.format('hl.bind(%q, hl.dsp.special.workspace({ name = %q }))', combo, cmd)
    elseif disp == "movetoworkspacesilent" then
        return string.format('hl.bind(%q, hl.dsp.window.move_to_workspace({ workspace = %q, silent = true }))', combo, cmd)
    elseif disp == "layoutmsg" then
        return string.format('hl.bind(%q, hl.dsp.layoutmsg(%q))', combo, cmd)
    else
        -- Fallback: usar hyprctl dispatch directamente. Marca TODO para revisión manual.
        return string.format('-- TODO_LUA_BIND: type=%s mods=%s key=%s dispatcher=%s command=%s',
            b.type or "bind", mods, key, disp, cmd)
    end
end

-- Binds hardcoded del usuario que NO están en settings.json.
-- Si el JSON trae binds, ganan; esto es fallback 1:1 con keybindings.conf actual.
local HARDCODED_BINDS = [[
-- Binds hardcoded (preservados de keybindings.conf mientras no estén en JSON)
-- Gestures & mouse
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })
-- Float toggle + center + resize (code:64 = Space en teclado latam)
hl.bind("SUPER ALT, space", hl.dsp.exec_cmd("hyprctl --batch \"dispatch togglefloating ; dispatch centerwindow ; dispatch resizeactive exact 500 350\""), { locked = true })
-- Scratchpad special
hl.bind(mainMod .. " + S", hl.dsp.special.workspace({ name = "special" }))
hl.bind("SUPER ALT, S", hl.dsp.window.move_to_workspace({ workspace = "special", silent = true }))
-- Game mode
hl.bind("SUPER ALT, G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle-game-mode.sh"))
-- Olive shader
hl.bind("SUPER SHIFT, G", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/toggle-olive-shader.sh"))
-- Screenshot OCR / full / edit (los no cubiertos por Print ya están en JSON)
hl.bind("SUPER SHIFT, S", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh"))
hl.bind("SUPER SHIFT, O", hl.dsp.exec_cmd("~/.config/hypr/scripts/screenshot.sh --ocr"))
hl.bind("SUPER ALT, R", hl.dsp.exec_cmd("~/.config/hypr/scripts/screen_record.sh"))
hl.bind("SUPER, D", hl.dsp.exec_cmd("bash ~/.config/hypr/scripts/screen_draw.sh"))
-- Focus next monitor
hl.bind(mainMod .. " + TAB", hl.dsp.exec_cmd("~/.config/hypr/scripts/focus_next_monitor.sh"))
]]

local function main()
    local args = arg or {}
    if #args < 4 then
        io.stderr:write("uso: compile_settings.lua <settings.json> <default.json> <out_dir> <templates_dir>\n")
        os.exit(2)
    end
    local settings_file, default_file, out_dir, tmpl_dir =
        args[1], args[2], args[3], args[4]

    -- Asegurar out_dir
    os.execute("mkdir -p " .. shell_quote(out_dir .. "/config"))

    -- === 1. variables.lua ===
    local main_mod  = str(jq('."$mainMod" // "SUPER"', settings_file), "SUPER")
    local terminal  = str(jq('.terminal // "kitty"', settings_file), "kitty")
    local vars_t = read_file(tmpl_dir .. "/config.variables.lua.template")
    vars_t = vars_t:gsub("{{MAIN_MOD}}", main_mod):gsub("{{TERMINAL}}", terminal)
    write_file(out_dir .. "/config/variables.lua", vars_t)

    -- === 2. env.lua ===
    local extra_env = ""
    local env_t = read_file(tmpl_dir .. "/config.env.lua.template")
    env_t = env_t:gsub("{{EXTRA_ENV}}", extra_env)
    write_file(out_dir .. "/config/env.lua", env_t)

    -- === 3. autostart.lua ===
    local autostart_lines = {}
    local p = io.popen("jq -r '.startup[]?.command // empty' " .. shell_quote(settings_file) .. " 2>/dev/null")
    if p then
        for line in p:lines() do
            -- p:lines() ya chompea. Filtrar vacíos y null.
            if line ~= "" and line ~= "null" then
                -- No se auto-arranca el propio watcher (responsabilidad del .conf legacy)
                if not line:match("settings_watcher%.sh") then
                    table.insert(autostart_lines, '  hl.exec_cmd(' .. lua_quote(line) .. ')')
                end
            end
        end
        p:close()
    end
    local autostart_t = read_file(tmpl_dir .. "/config.autostart.lua.template")
    autostart_t = autostart_t:gsub("{{AUTOSTART_LINES}}", table.concat(autostart_lines, "\n"))
    write_file(out_dir .. "/config/autostart.lua", autostart_t)

    -- === 4. monitors.lua ===
    local mon_lines = {}
    p = io.popen("jq -r '.monitors[]? | @json' " .. shell_quote(settings_file) .. " 2>/dev/null")
    if p then
        for line in p:lines() do
            if line ~= "" and line ~= "null" then
                -- Mínimo parseo: extraer campos con jq anidado para evitar json.lua
                local n   = str(jq('.monitors[] | select(.name == "' .. (line:match('"name"%s*:%s*"([^"]+)"') or "") .. '") | .name', settings_file), "")
                local rw  = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .resW', settings_file), 0)
                local rh  = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .resH', settings_file), 0)
                local r   = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .rate', settings_file), 60)
                local x   = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .x', settings_file), 0)
                local y   = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .y', settings_file), 0)
                local sc  = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .scale', settings_file), 1)
                local tr  = tonum(jq('.monitors[] | select(.name == "' .. n .. '") | .transform // 0', settings_file), 0)
                if n ~= "" and rw > 0 and rh > 0 then
                    table.insert(mon_lines, string.format(
                        'hl.monitor({ output = %q, mode = %q, position = { x = %d, y = %d }, scale = %s%s })',
                        n, string.format("%dx%d@%d", rw, rh, r), x, y, tostring(sc),
                        tr > 0 and (", transform = " .. tostring(tr)) or ""))
                end
            end
        end
        p:close()
    end
    if #mon_lines == 0 then
        mon_lines = { 'hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.0 })' }
    end
    -- Workspace rules impares/pares
    local ws_rules = {}
    table.insert(ws_rules, '-- Workspace rules (odd -> HDMI-A-1, even -> DP-2)')
    for i = 1, 10 do
        local mon = (i % 2 == 1) and "HDMI-A-1" or "DP-2"
        table.insert(ws_rules, string.format('hl.workspace({ id = %d, monitor = %q, default = true })', i, mon))
    end
    local mon_t = read_file(tmpl_dir .. "/config.monitors.lua.template")
    mon_t = mon_t:gsub("{{MONITORS}}", table.concat(mon_lines, "\n"))
                   :gsub("{{WORKSPACE_RULES}}", table.concat(ws_rules, "\n"))
    write_file(out_dir .. "/config/monitors.lua", mon_t)

    -- === 5. settings.lua ===
    local sett_t = read_file(tmpl_dir .. "/config.settings.lua.template")
    local function sub(pat, val)
        local s
        if type(val) == "boolean" then s = tostring(val)
        elseif type(val) == "number" then s = tostring(val)
        elseif val == nil then s = "nil"
        else s = tostring(val) end
        sett_t = sett_t:gsub(pat, escape_replacement(s))
    end
    sub("{{BORDER_SIZE}}",            tonum(jq('.borderSize // 0',           settings_file), 0))
    sub("{{GAPS_IN}}",                tonum(jq('.gapsIn // 4',               settings_file), 4))
    sub("{{GAPS_OUT}}",               tonum(jq('.gapsOut // 6',              settings_file), 6))
    sub("{{FLOAT_GAPS}}",             tonum(jq('.floatGaps // 6',            settings_file), 6))
    sub("{{RESIZE_ON_BORDER}}",       tostring(tobool(jq('.resizeOnBorder // true', settings_file), true)))
    sub("{{EXTEND_BORDER_GRAB_AREA}}",tonum(jq('.extendBorderGrab // 30',    settings_file), 30))
    sub("{{ROUNDING}}",               tonum(jq('.rounding // 12',            settings_file), 12))
    sub("{{ACTIVE_OPACITY}}",         tonum(jq('.activeOpacity // 1.0',      settings_file), 1.0))
    sub("{{INACTIVE_OPACITY}}",       tonum(jq('.inactiveOpacity // 1.0',    settings_file), 1.0))
    sub("{{BLUR_ENABLED}}",           tostring(tobool(jq('.blurEnabled // true', settings_file), true)))
    sub("{{BLUR_SIZE}}",              tonum(jq('.blurSize // 8',             settings_file), 8))
    sub("{{BLUR_PASSES}}",            tonum(jq('.blurPasses // 2',           settings_file), 2))
    sub("{{BLUR_NEW_OPT}}",           tostring(tobool(jq('.blurNewOpt // true', settings_file), true)))
    sub("{{SHADOW_ENABLED}}",         tostring(tobool(jq('.shadowEnabled // false', settings_file), false)))
    sub("{{KB_LAYOUT}}",              str(jq('.language // "latam,us"',      settings_file), "latam,us"))
    sub("{{KB_OPTIONS}}",             str(jq('.kbOptions // "grp:alt_shift_toggle"', settings_file), "grp:alt_shift_toggle"))
    sub("{{ACCEL_PROFILE}}",          str(jq('.accelProfile // "flat"',      settings_file), "flat"))
    sub("{{TOUCHPAD_NATURAL}}",       tostring(tobool(jq('.touchpadNatural // true', settings_file), true)))
    sub("{{TOUCHPAD_DWT}}",           tostring(tobool(jq('.touchpadDwt // false', settings_file), false)))
    sub("{{FOCUS_ON_ACTIVATE}}",      tostring(tobool(jq('.focusOnActivate // false', settings_file), false)))
    sub("{{FONT_FAMILY}}",            str(jq('.fontFamily // "JetBrains Mono"', settings_file), "JetBrains Mono"))
    sub("{{DISABLE_HL_LOGO}}",        tostring(tobool(jq('.disableHlLogo // true', settings_file), true)))
    sub("{{DISABLE_SPLASH}}",         tostring(tobool(jq('.disableSplash // true', settings_file), true)))
    sub("{{ANIMATIONS}}",             [[
hl.curve("myBezier", { type = "bezier", points = { {0.05, 0.9}, {0.1, 1.05} } })
hl.animation({ leaf = "windows",              enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "windowsOut",           enabled = true, speed = 5, bezier = "myBezier", style = "popin 80%" })
hl.animation({ leaf = "layers",               enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersIn",             enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "layersOut",            enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "fade",                 enabled = true, speed = 5, bezier = "myBezier" })
hl.animation({ leaf = "workspaces",           enabled = true, speed = 5, bezier = "myBezier", style = "slide" })
hl.animation({ leaf = "specialWorkspaceIn",  enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
hl.animation({ leaf = "specialWorkspaceOut", enabled = true, speed = 5, bezier = "myBezier", style = "fade" })
]])
    sub("{{DEVICES}}",                [[
-- Tablet pen -> HDMI-A-1
hl.device({ name = "huion-huion-tablet-pen", output = "HDMI-A-1" })
]])
    write_file(out_dir .. "/config/settings.lua", sett_t)

    -- === 6. keybinds.lua ===
    local kb_lines = {}
    p = io.popen("jq -r '.keybinds[]? | @json' " .. shell_quote(settings_file) .. " 2>/dev/null")
    if p then
        for line in p:lines() do
            if line ~= "" and line ~= "null" then
                -- Re-extraer campos del JSON crudo (Lua no parsea JSON nativo)
                local function jget(field, json_str)
                    local v = json_str:match('"' .. field .. '"%s*:%s*"([^"]*)"') or
                              json_str:match('"' .. field .. '"%s*:%s*(%d+%.?%d*)') or
                              json_str:match('"' .. field .. '"%s*:%s*(true|false|null)')
                    return v
                end
                local bind = {
                    type        = jget("type",        line),
                    mods        = jget("mods",        line) or "",
                    key         = jget("key",         line) or "",
                    dispatcher  = jget("dispatcher",  line) or "exec",
                    command     = jget("command",     line) or "",
                    locked      = jget("locked",      line) or "false",
                }
                table.insert(kb_lines, translate_bind(bind, main_mod))
            end
        end
        p:close()
    end
    local kb_t = read_file(tmpl_dir .. "/config.keybinds.lua.template")
    kb_t = kb_t:gsub("{{KEYBINDS}}", table.concat(kb_lines, "\n") .. "\n" .. HARDCODED_BINDS)
    write_file(out_dir .. "/config/keybinds.lua", kb_t)

    -- === 7. rules.lua (placeholder extensible) ===
    local rules_t = read_file(tmpl_dir .. "/config.rules.lua.template")
    rules_t = rules_t:gsub("{{RULES}}", "-- (sin windowrules aún — añadir vía JSON cuando esté disponible)")
    write_file(out_dir .. "/config/rules.lua", rules_t)

    -- === 8. hyprland.lua entry point ===
    local hl_ver = str(jq('."_hyprlandVersion" // ""', settings_file), "")
    local entry_t = read_file(tmpl_dir .. "/hyprland.lua.template")
    entry_t = entry_t:gsub("{{GENERATED_AT}}", os.date("%Y-%m-%d %H:%M:%S"))
                    :gsub("{{HL_VERSION}}", hl_ver)
                    :gsub("{{TARGET}}", "lua")
    write_file(out_dir .. "/hyprland.lua", entry_t)

    -- === Validación con luac -p ===
    local function validate(path)
        local f = io.popen("luac -p " .. shell_quote(path) .. " 2>&1")
        if not f then return false, "no pude invocar luac" end
        local out = f:read("*a"); f:close()
        return out == "", out
    end
    local files_to_check = {
        "hyprland.lua", "config/variables.lua", "config/env.lua",
        "config/autostart.lua", "config/monitors.lua", "config/settings.lua",
        "config/keybinds.lua", "config/rules.lua",
    }
    local bad = {}
    for _, rel in ipairs(files_to_check) do
        local ok, msg = validate(out_dir .. "/" .. rel)
        if not ok then table.insert(bad, rel .. ":\n" .. msg) end
    end
    if #bad > 0 then
        io.stderr:write("VALIDACIÓN FALLÓ en " .. #bad .. " archivos:\n")
        for _, m in ipairs(bad) do io.stderr:write(m .. "\n---\n") end
        os.exit(3)
    end
    io.write("ok: 8 archivos generados y validados con luac -p en " .. out_dir .. "\n")
end

main()
