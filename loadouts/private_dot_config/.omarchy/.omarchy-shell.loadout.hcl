# The Omarchy shell: plugins, the bar (position, thickness, icon size,
# widgets), the Pomodoro timer, Keystroke's Windows extension and how long
# the session idles before it locks.

# Plugins from git, one URL per argument, each installed and enabled the
# Omarchy way; and whether each is behind its remote.
script "omarchy-plugins" {
  description        = "Omarchy shell plugins installed and enabled"
  managed_by         = ".loadout/omarchy-plugins.sh"
  updates_managed_by = ".loadout/outdated-plugins.sh"
}

# Position, thickness, optionally the icon size and a widget replacing the
# workspace numbers: "top", "24", "17", "<widget-id>".
script "omarchy-bar" {
  description = "Omarchy bar position, thickness, icon size, workspace widget and its settings"
  managed_by  = ".loadout/omarchy-bar.sh"
  run_after   = [script.omarchy-plugins]
}

# This repo's own bar widgets (.loadout/omarchy-bar/plugins/<id>), one id
# per argument; it also removes what omarchy-bar-icons installed before
# Omarchy 4.5.
script "omarchy-bar-own-widgets" {
  description = "This repo's own bar widgets, installed and enabled"
  managed_by  = ".loadout/omarchy-bar-own-widgets.sh"
  run_after   = [script.omarchy-plugins]
}

# Where widgets sit: one argument per widget, "<id> <section>
# <before|after> <neighbour-id>" (see widget()); a widget off the bar is put
# on it.
script "omarchy-bar-widgets" {
  description = "Bar widgets' places and settings"
  managed_by  = ".loadout/omarchy-bar-widgets.sh"
  run_after   = [script.omarchy-plugins, script.omarchy-bar-own-widgets]
}

script "omarchy-pomodoro" {
  description = "Pomodoro timer: 50+10, Trigger menu entries"
  managed_by  = ".loadout/omarchy-pomodoro.sh"
  run_after   = [script.omarchy-plugins]
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

# The bar this repo's Omarchy machines share: its plugins, which widgets it
# shows and where the widgets sit. A profile runs `omarchy_bar()`, so the
# settings live beside the scripts that apply them.
function "omarchy_bar" {
  params = []
  result = [
    args(script.omarchy-bar, "top", "24", "17", "tornikegomareli.spaces"),
    args(script.omarchy-plugins,
      "https://github.com/evindor/keystroke.git",
      "https://github.com/tornikegomareli/omarchy-spaces.git",
      "https://github.com/binoymanoj/pomodoro-omarchy.git",
      "https://github.com/Zeus-Deus/voxtype-omarchy-plugin.git",
      "https://github.com/sumdahl/omarchy-plugin-media.git",
    ),
    args(script.omarchy-bar-own-widgets, "josemiguelo.workspace-layout", "josemiguelo.theme-mode"),
    args(script.omarchy-bar-widgets,
      widget("josemiguelo.workspace-layout", "left", "before", "tornikegomareli.spaces"),
      widget("evindor.keystroke", "left", "before", "josemiguelo.workspace-layout"),
      widget("pomodoro-omarchy", "centerEnd", "before", "omarchy.weather"),
      widget("omarchy.elsewhen", "centerEnd", "before", "pomodoro-omarchy"),
      widget("io.github.sumdahl.media", "right", "after", "omarchy.tray"),
      widget("omarchy.power", "right", "after", "omarchy.monitor"),
      widget("josemiguelo.theme-mode", "right", "before", "omarchy.tray"),
    ),
    script.omarchy-keystroke-windows,
    script.omarchy-pomodoro,
  ]
}
