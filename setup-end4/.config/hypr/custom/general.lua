-- Monitores: HDMI-A-1 (izq, primario) y DP-2 (der, secundario)
-- Workspaces impares (1,3,5,7,9) en HDMI-A-1
hl.workspace_rule({ workspace = "1", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "3", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "5", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "7", monitor = "HDMI-A-1", default = true })
hl.workspace_rule({ workspace = "9", monitor = "HDMI-A-1", default = true })

-- Workspaces pares (2,4,6,8,10) en DP-2
hl.workspace_rule({ workspace = "2", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "4", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "6", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "8", monitor = "DP-2", default = true })
hl.workspace_rule({ workspace = "10", monitor = "DP-2", default = true })

-- ==========================================
-- Configuración de Pantalla y Teclado Personalizada
-- ==========================================

-- Monitores
hl.monitor({
    output = "HDMI-A-1",
    mode = "preferred",
    position = "0x0",
    scale = "1"
})
hl.monitor({
    output = "DP-2",
    mode = "preferred",
    position = "1366x0",
    scale = "1"
})

-- Teclado y VRR (Tasa de Refresco Variable)
hl.config({
    input = {
        kb_layout = "latam"
    },
    misc = {
        vrr = 2,
        swallow_regex = "(foot|kitty|allacritty|Alacritty|wezterm|org%.wezfurlong%.wezterm)"
    }
})

-- Mapear tableta gráfica HUION al monitor HDMI-A-1
hl.device({
    name = "huion-huion-tablet-pen",
    output = "HDMI-A-1"
})

