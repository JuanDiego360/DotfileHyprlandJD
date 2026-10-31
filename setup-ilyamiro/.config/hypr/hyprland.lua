-- --------------------------------------------------------------------------------------
--   Hyprland 0.57+ Lua Modular Configuration
--   (Compatible with CachyOS / Arch Linux setup-ilyamiro)
-- --------------------------------------------------------------------------------------

require("lua/variables")
require("lua/env")
require("lua/autostart")
require("lua/monitors")
require("lua/settings")
require("lua/rules")
require("lua/keybinds")

-- Submap passthru (Quickshell input pass-through)
hl.define_submap("passthru", function()
  hl.bind("SUPER SHIFT CTRL ALT, F35", function() end)
  hl.bind("SUPER, Escape", hl.dsp.submap("reset"))
end)

-- Tablet Pen binding
hl.device({
  name = "huion-huion-tablet-pen",
  output = "HDMI-A-1",
})
