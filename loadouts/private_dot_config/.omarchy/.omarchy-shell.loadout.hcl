# The Omarchy shell: plugins, the bar (position, thickness, icon size,
# widgets), the Pomodoro timer, Keystroke's Windows extension and how long
# the session idles before it locks.

# Plugins from git, one URL per argument, each installed and enabled the
# Omarchy way; and whether each is behind its remote.
script "omarchy-plugins" {
  description        = "Omarchy shell plugins installed and enabled"
  managed_by         = ".loadout/omarchy-plugins.ts"
  updates_managed_by = ".loadout/outdated-plugins.ts"
}

# The bar itself, one key=value per argument: "position=top", "size=24",
# optionally "background=glassy", "icon-size=17" and "off=<stock-widget-id>"
# (repeats).
script "omarchy-bar" {
  description = "Omarchy bar position, background, thickness, icon size and stock widgets turned off"
  managed_by  = ".loadout/omarchy-bar.ts"
  run_after   = [script.omarchy-plugins]
}

# This repo's own bar widgets (.loadout/omarchy-bar/plugins/<id>), one id
# per argument.
script "omarchy-bar-own-widgets" {
  description = "This repo's own bar widgets, installed and enabled"
  managed_by  = ".loadout/omarchy-bar-own-widgets.ts"
  run_after   = [script.omarchy-plugins]
}

# Where widgets sit and their settings (.loadout/omarchy-bar/settings/<id>.json):
# one argument per widget, "<id> <section> <before|after> <neighbour-id>" or
# "<id> <section> at <index>" (see widget()); a widget off the bar is put on
# it. They're placed in order, so a neighbour is a widget already in that
# section on a stock bar, or one placed by an earlier line.
script "omarchy-bar-widgets" {
  description = "Bar widgets' places and settings"
  managed_by  = ".loadout/omarchy-bar-widgets.ts"
  run_after   = [script.omarchy-plugins, script.omarchy-bar-own-widgets]
}

script "omarchy-pomodoro" {
  description = "Pomodoro timer: 50+10, Trigger menu entries"
  managed_by  = ".loadout/omarchy-pomodoro.ts"
  run_after   = [script.omarchy-plugins]
}

# Seconds idle before the session locks and the display goes off: "1000".
script "omarchy-idle" {
  description = "the session locks after the opt-in's seconds idle"
  managed_by  = ".loadout/omarchy-idle.ts"
}

# Appearance > This Workspace's Layout in the Omarchy menu: each layout for
# the focused workspace only (omarchy-workspace-layout-set), with Omarchy's
# own entry relabelled "Default Workspace Layout".
script "omarchy-workspace-layout-menu" {
  description = "Menu entries setting the focused workspace's layout only"
  managed_by  = ".loadout/omarchy-workspace-layout-menu.ts"
}

script "omarchy-keystroke-windows" {
  description = "Hyper+Space lists every window, by workspace (Keystroke)"
  managed_by  = ".loadout/omarchy-keystroke-windows.ts"
  run_after   = [script.omarchy-plugins]
}

# One omarchy-bar-widgets argument: widget("x", "left", "before", "y")
# reads as the bar does; widget("x", "center", "at", "0") places it by index.
function "widget" {
  params = [id, section, where, neighbour]
  result = "${id} ${section} ${where} ${neighbour}"
}

# The bar this repo's Omarchy machines share, as what differs from a fresh
# Omarchy install: its plugins, which widgets it shows, where the widgets sit
# and the settings that aren't stock. A stock widget at its stock place and
# settings is left out. A profile runs `omarchy_bar()`, so the
# settings live beside the scripts that apply them.
function "omarchy_bar" {
  params = []
  result = [
    args(script.omarchy-bar, "position=top", "size=24", "background=glassy", "off=omarchy.workspaces"),
    args(script.omarchy-plugins,
      "https://github.com/evindor/keystroke.git",
      "https://github.com/tornikegomareli/omarchy-spaces.git",
      "https://github.com/binoymanoj/pomodoro-omarchy.git",
      "https://github.com/sumdahl/omarchy-plugin-media.git",
      "https://github.com/josemiguelo/omarchy-harpoon.git",
    ),
    args(script.omarchy-bar-own-widgets, "josemiguelo.workspace-layout", "josemiguelo.theme-mode"),
    args(script.omarchy-bar-widgets,
      widget("evindor.keystroke", "left", "at", "0"),
      widget("josemiguelo.workspace-layout", "left", "after", "evindor.keystroke"),
      widget("tornikegomareli.spaces", "left", "after", "josemiguelo.workspace-layout"),
      widget("pomodoro-omarchy", "centerEnd", "before", "omarchy.weather"),
      widget("omarchy.elsewhen", "centerEnd", "before", "pomodoro-omarchy"),
      widget("io.github.sumdahl.media", "right", "after", "omarchy.tray"),
      widget("omarchy.power", "right", "after", "omarchy.monitor"),
      widget("josemiguelo.theme-mode", "right", "before", "omarchy.tray"),
      widget("omarchy.keyboard-layout", "right", "before", "josemiguelo.theme-mode"),
      widget("omarchy.clock", "center", "at", "0"),
    ),
    script.omarchy-keystroke-windows,
    script.omarchy-pomodoro,
  ]
}
