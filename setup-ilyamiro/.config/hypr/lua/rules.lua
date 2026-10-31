-- Layer rules
hl.layer_rule({ name = "lr1", match = { namespace = "^(volume_osd)$" }, no_anim = true })
hl.layer_rule({ name = "lr2", match = { namespace = "^(brightness_osd)$" }, no_anim = true })
hl.layer_rule({ name = "lr3", match = { namespace = "hyprpicker" }, no_anim = true })
hl.layer_rule({ name = "lr4", match = { namespace = "qsdock" }, no_anim = true })
hl.layer_rule({ name = "lr5", match = { namespace = "ext-session-lock" }, blur = true, ignore_alpha = 0.2 })

-- Window rules
hl.window_rule({
  name = "app_launcher",
  match = { title = "^(app-launcher)$" },
  float = true,
  center = true,
  size = { 1200, 600 },
  animation = "slide",
})

hl.window_rule({
  name = "master_rule",
  match = { title = "^(qs-master)$" },
  float = true,
  no_shadow = true,
  no_initial_focus = true,
})

hl.window_rule({
  name = "satty",
  match = { class = "^(com\\.gabm\\.satty)$" },
  float = true,
  center = true,
  size = { "75%", "75%" },
})

hl.window_rule({
  name = "satty_freeze",
  match = { class = "^(com\\.gabm\\.sattyfreeze)$" },
  fullscreen = true,
  float = true,
  no_anim = true,
})
