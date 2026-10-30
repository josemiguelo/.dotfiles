# The Omarchy shell: plugins, the bar (position, widgets, icons, the menu
# button), the Pomodoro timer, Keystroke's Windows extension and how long
# the session idles before it locks.

# Plugins from git, one URL per argument, each installed and enabled the
# Omarchy way; and whether each is behind its remote.
script "omarchy-plugins" {
  description        = "Omarchy shell plugins installed and enabled"
  managed_by         = ".loadout/omarchy-plugins.sh"
  updates_managed_by = ".loadout/outdated-plugins.sh"
}

# Position, thickness, and optionally a widget replacing the workspace
# numbers: "top", "24", "<widget-id>".
script "omarchy-bar" {
  description = "Omarchy bar position, thickness, workspace widget and its settings"
  managed_by  = ".loadout/omarchy-bar.sh"
  run_after   = [script.omarchy-plugins]
}

# Widgets with SVG icons, rebuilt from their source in the original's place
# (github.com/josemiguelo/omarchy-bar-icons).
script "omarchy-bar-icons" {
  description = "Bar widgets with SVG icons, rebuilt from their source"
  managed_by  = ".loadout/omarchy-bar-icons.sh"
  run_after   = [script.omarchy-plugins]
}

# Where widgets sit: one argument per widget, "<id> <left|right>
# <before|after> <neighbour-id>" (see widget()).
script "omarchy-bar-widgets" {
  description = "Bar widgets' places and settings"
  managed_by  = ".loadout/omarchy-bar-widgets.sh"
  run_after   = [script.omarchy-plugins, script.omarchy-bar-icons]
}

script "omarchy-menu-button" {
  description = "The menu button in the place of Keystroke's bar button"
  managed_by  = ".loadout/omarchy-menu-button.sh"
  run_after   = [script.omarchy-plugins, script.omarchy-bar-icons]
}

script "omarchy-pomodoro" {
  description = "Pomodoro timer: by the clock, 50+10, Trigger menu entries"
  managed_by  = ".loadout/omarchy-pomodoro.sh"
  run_after   = [script.omarchy-plugins, script.omarchy-bar-icons]
}

# Seconds idle before the session locks and the display goes off: "1000".
script "omarchy-idle" {
  description = "the session locks after the opt-in's seconds idle"
  managed_by  = ".loadout/omarchy-idle.sh"
}

script "omarchy-keystroke-windows" {
  description = "Hyper+Space lists every window, by workspace (Keystroke)"
  managed_by  = ".loadout/omarchy-keystroke-windows.sh"
  run_after   = [script.omarchy-plugins]
}

# One omarchy-bar-widgets argument: widget("x", "left", "before", "y")
# reads as the bar does.
function "widget" {
  params = [id, section, where, neighbour]
  result = "${id} ${section} ${where} ${neighbour}"
}

# The bar this repo's Omarchy machines share: its plugins, which icons it
# shows and where the widgets sit. A profile runs `omarchy_bar()`, so the
# settings live beside the scripts that apply them.
function "omarchy_bar" {
  params = []
  result = [
    args(script.omarchy-bar, "top", "24", "tornikegomareli.spaces"),
    args(script.omarchy-plugins,
      "https://github.com/evindor/keystroke.git",
      "https://github.com/jankeesvw/omarchy-notification-center.git",
      "https://github.com/tornikegomareli/omarchy-spaces.git",
      "https://github.com/binoymanoj/pomodoro-omarchy.git",
      "https://github.com/Zeus-Deus/voxtype-omarchy-plugin.git",
      "https://github.com/sumdahl/omarchy-plugin-media.git",
    ),
    args(script.omarchy-bar-icons,
      "josemiguelo.menu-button", "josemiguelo.workspace-layout", "josemiguelo.theme-mode",
      "omarchy.monitor", "omarchy.bluetooth", "omarchy.network", "omarchy.audio",
      "omarchy.power", "omarchy.agents", "omarchy.system-update", "omarchy.indicators",
      "omarchy.weather", "omarchy.tray",
      "jankeesvw.notification-center", "io.github.zeus-deus.voxtype", "io.github.sumdahl.media",
      "pomodoro-omarchy", "omarchy.clock", "tornikegomareli.spaces",
    ),
    args(script.omarchy-bar-widgets,
      widget("josemiguelo.workspace-layout", "left", "before", "tornikegomareli.spaces"),
      widget("josemiguelo.menu-button", "left", "before", "josemiguelo.workspace-layout"),
      widget("io.github.sumdahl.media", "right", "after", "omarchy.tray"),
      widget("omarchy.power", "right", "after", "omarchy.monitor"),
      widget("josemiguelo.theme-mode", "right", "before", "omarchy.tray"),
    ),
    script.omarchy-menu-button,
    script.omarchy-keystroke-windows,
    script.omarchy-pomodoro,
  ]
}
