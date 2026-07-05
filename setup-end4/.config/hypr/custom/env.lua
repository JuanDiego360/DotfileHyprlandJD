-- Game-specific environment variables
-- Optimizes Steam and games for Wayland/Hyprland

hl.env("SDL_VIDEODRIVER", "x11")         -- X11 para juegos (mejor captura de mouse)
hl.env("CLUTTER_BACKEND", "wayland")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- Fix Steam's "Big Picture" and scaling issues
hl.env("STEAM_FRAME_FORCE_CLOSE", "1")

-- Gaming performance optimizations
-- WARNING: NO usar WLR_DRM_NO_MODIFIERS=1 — rompe el input del mouse en juegos
hl.env("vblank_mode", "0")               -- Desactivar vsync del driver (para VRR)
hl.env("mesa_glthread", "true")          -- Mejor rendimiento OpenGL en AMD
hl.env("PROTON_ENABLE_NVAPI", "1")       -- Habilitar DLSS/tecnologías NV en Proton
hl.env("PROTON_USE_WINED3D", "0")        -- Usar DXVK (mejor rendimiento)
hl.env("DXVK_ASYNC", "1")                -- Compilación asíncrona de shaders

-- Entorno virtual de python para Quickshell
hl.env("ILLOGICAL_IMPULSE_VIRTUAL_ENV", os.getenv("HOME") .. "/.local/state/quickshell/.venv")

