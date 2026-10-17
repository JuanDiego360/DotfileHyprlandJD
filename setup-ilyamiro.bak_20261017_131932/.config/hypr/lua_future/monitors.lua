-- Physical Monitors
hl.monitor({
  output = "DP-2",
  mode = "1280x1024@60",
  position = "1366x0",
  scale = 1.0,
})

hl.monitor({
  output = "HDMI-A-1",
  mode = "1366x768@60",
  position = "0x128",
  scale = 1.0,
})

-- Workspace to monitor bindings (Odd -> HDMI-A-1, Even -> DP-2)
local odd_workspaces = { 1, 3, 5, 7, 9 }
for _, ws in ipairs(odd_workspaces) do
  hl.workspace({ id = ws, monitor = "HDMI-A-1", default = true })
end

local even_workspaces = { 2, 4, 6, 8, 10 }
for _, ws in ipairs(even_workspaces) do
  hl.workspace({ id = ws, monitor = "DP-2", default = true })
end
