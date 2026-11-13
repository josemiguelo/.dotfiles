// The Omarchy shell: plugins, the bar (position, thickness, icon size,
// widgets), the Pomodoro timer, Keystroke's Windows extension and how long
// the session idles before it locks.
import { args, script } from "loadout";

// Plugins from git, one URL per argument, each installed and enabled the
// Omarchy way; and whether each is behind its remote.
export const omarchyPlugins = script("omarchy-plugins", {
  description: "Omarchy shell plugins installed and enabled",
  managedBy: ".loadout/omarchy-plugins.ts",
  updatesManagedBy: ".loadout/outdated-plugins.ts",
});

// The bar itself, one key=value per argument: "position=top", "size=24",
// optionally "background=glassy", "icon-size=17" and "off=<stock-widget-id>"
// (repeats).
export const omarchyBar = script("omarchy-bar", {
  description: "Omarchy bar position, background, thickness, icon size and stock widgets turned off",
  managedBy: ".loadout/omarchy-bar.ts",
  runAfter: [omarchyPlugins],
});

// This repo's own bar widgets (.loadout/omarchy-bar/plugins/<id>), one id
// per argument.
export const omarchyBarOwnWidgets = script("omarchy-bar-own-widgets", {
  description: "This repo's own bar widgets, installed and enabled",
  managedBy: ".loadout/omarchy-bar-own-widgets.ts",
  runAfter: [omarchyPlugins],
});

// Where widgets sit and their settings (.loadout/omarchy-bar/settings/<id>.json):
// one argument per widget, "<id> <section> <before|after> <neighbour-id>" or
// "<id> <section> at <index>" (see widget()); a widget off the bar is put on
// it. They're placed in order, so a neighbour is a widget already in that
// section on a stock bar, or one placed by an earlier line.
export const omarchyBarWidgets = script("omarchy-bar-widgets", {
  description: "Bar widgets' places and settings",
  managedBy: ".loadout/omarchy-bar-widgets.ts",
  runAfter: [omarchyPlugins, omarchyBarOwnWidgets],
});

export const omarchyPomodoro = script("omarchy-pomodoro", {
  description: "Pomodoro timer: 50+10, Trigger menu entries",
  managedBy: ".loadout/omarchy-pomodoro.ts",
  runAfter: [omarchyPlugins],
});

// Seconds idle before the session locks and the display goes off: "1000".
export const omarchyIdle = script("omarchy-idle", {
  description: "the session locks after the opt-in's seconds idle",
  managedBy: ".loadout/omarchy-idle.ts",
});

// Appearance > This Workspace's Layout in the Omarchy menu: each layout for
// the focused workspace only (omarchy-workspace-layout-set), with Omarchy's
// own entry relabelled "Default Workspace Layout".
export const omarchyWorkspaceLayoutMenu = script("omarchy-workspace-layout-menu", {
  description: "Menu entries setting the focused workspace's layout only",
  managedBy: ".loadout/omarchy-workspace-layout-menu.ts",
});

export const omarchyKeystrokeWindows = script("omarchy-keystroke-windows", {
  description: "Hyper+Space lists every window, by workspace (Keystroke)",
  managedBy: ".loadout/omarchy-keystroke-windows.ts",
  runAfter: [omarchyPlugins],
});

// One omarchy-bar-widgets argument: widget("x", "left", "before", "y")
// reads as the bar does; widget("x", "center", "at", "0") places it by index.
export const widget = (id: string, section: string, where: string, neighbour: string) => `${id} ${section} ${where} ${neighbour}`;

// The bar this repo's Omarchy machines share, as what differs from a fresh
// Omarchy install: its plugins, which widgets it shows, where the widgets sit
// and the settings that aren't stock. A stock widget at its stock place and
// settings is left out. A profile runs `omarchyBar()`, so the
// settings live beside the scripts that apply them.
export const omarchyBarFn = () => [
  args(omarchyBar, "position=top", "size=24", "background=glassy", "off=omarchy.workspaces"),
  args(
    omarchyPlugins,
    "https://github.com/evindor/keystroke.git",
    "https://github.com/tornikegomareli/omarchy-spaces.git",
    "https://github.com/binoymanoj/pomodoro-omarchy.git",
    "https://github.com/sumdahl/omarchy-plugin-media.git",
    "https://github.com/josemiguelo/omarchy-harpoon.git",
  ),
  args(omarchyBarOwnWidgets, "josemiguelo.workspace-layout", "josemiguelo.theme-mode"),
  args(
    omarchyBarWidgets,
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
    // Stock, but listed: a stray drag on the bar drops it in another section,
    // and only a listed widget gets put back.
    widget("omarchy.indicators", "centerBegin", "at", "0"),
  ),
  omarchyKeystrokeWindows,
  omarchyPomodoro,
];
