// The Omarchy shell: plugins, the bar (position, thickness, icon size,
// widgets), the Pomodoro timer, Keystroke's Windows extension and how long
// the session idles before it locks.
import { script } from "loadout";
import type { Widget } from "./.loadout/omarchy-bar-widgets.rules.ts";

// Plugins from git, by URL, each installed and enabled the
// Omarchy way; and whether each is behind its remote.
export const omarchyPlugins = script("omarchy-plugins", {
  description: "Omarchy shell plugins installed and enabled",
  module: () => import("./.loadout/omarchy-plugins.ts"),
  rules: () => import("./.loadout/omarchy-plugins.rules.ts"),
  updates: () => import("./.loadout/outdated-plugins.ts"),
});

// The bar itself: position, thickness, background, icon size and stock widgets
// turned off.
export const omarchyBar = script("omarchy-bar", {
  description: "Omarchy bar position, background, thickness, icon size and stock widgets turned off",
  module: () => import("./.loadout/omarchy-bar.ts"),
  rules: () => import("./.loadout/omarchy-bar.rules.ts"),
  runAfter: [omarchyPlugins],
});

// This repo's own bar widgets (.loadout/omarchy-bar/plugins/<id>), by id.
export const omarchyBarOwnWidgets = script("omarchy-bar-own-widgets", {
  description: "This repo's own bar widgets, installed and enabled",
  module: () => import("./.loadout/omarchy-bar-own-widgets.ts"),
  rules: () => import("./.loadout/omarchy-bar-own-widgets.rules.ts"),
  runAfter: [omarchyPlugins],
});

// Where widgets sit and their settings (.loadout/omarchy-bar/settings/<id>.json);
// a widget off the bar is put on it. They're placed in order, so a neighbour is
// a widget already in that section on a stock bar, or one placed before it.
export const omarchyBarWidgets = script("omarchy-bar-widgets", {
  description: "Bar widgets' places and settings",
  module: () => import("./.loadout/omarchy-bar-widgets.ts"),
  rules: () => import("./.loadout/omarchy-bar-widgets.rules.ts"),
  runAfter: [omarchyPlugins, omarchyBarOwnWidgets],
});

export const omarchyPomodoro = script("omarchy-pomodoro", {
  description: "Pomodoro timer: 50+10, Trigger menu entries",
  module: () => import("./.loadout/omarchy-pomodoro.ts"),
  runAfter: [omarchyPlugins],
});

// Seconds idle before the session locks and the display goes off: "1000".
export const omarchyIdle = script("omarchy-idle", {
  description: "the session locks after the machine's seconds idle",
  module: () => import("./.loadout/omarchy-idle.ts"),
  rules: () => import("./.loadout/omarchy-idle.rules.ts"),
});

// Appearance > This Workspace's Layout in the Omarchy menu: each layout for
// the focused workspace only (omarchy-workspace-layout-set), with Omarchy's
// own entry relabelled "Default Workspace Layout".
export const omarchyWorkspaceLayoutMenu = script("omarchy-workspace-layout-menu", {
  description: "Menu entries setting the focused workspace's layout only",
  module: () => import("./.loadout/omarchy-workspace-layout-menu.ts"),
});

export const omarchyKeystrokeWindows = script("omarchy-keystroke-windows", {
  description: "Hyper+Space lists every window, by workspace (Keystroke)",
  module: () => import("./.loadout/omarchy-keystroke-windows.ts"),
  runAfter: [omarchyPlugins],
});

// The bar this repo's Omarchy machines share, as what differs from a fresh
// Omarchy install: its plugins, which widgets it shows, where the widgets sit
// and the settings that aren't stock. A stock widget at its stock place and
// settings is left out. A profile runs `omarchyBarFn()`, so the
// settings live beside the scripts that apply them. A profile for some of
// those machines passes what only they add (`extra`): its call replaces the
// shared one, since what a profile calls a script with wins over the profile it extends.
export const omarchyBarFn = (extra: { plugins?: string[]; widgets?: Widget[] } = {}) => [
  omarchyBar({ position: "top", size: 24, background: "glassy", off: ["omarchy.workspaces"] }),
  omarchyPlugins({
    urls: [
      "https://github.com/evindor/keystroke.git",
      "https://github.com/tornikegomareli/omarchy-spaces.git",
      "https://github.com/binoymanoj/pomodoro-omarchy.git",
      "https://github.com/sumdahl/omarchy-plugin-media.git",
      "https://github.com/josemiguelo/omarchy-harpoon.git",
      ...(extra.plugins ?? []),
    ],
  }),
  omarchyBarOwnWidgets({ ids: ["josemiguelo.workspace-layout", "josemiguelo.theme-mode"] }),
  omarchyBarWidgets({
    widgets: [
      { id: "evindor.keystroke", section: "left", at: 0 },
      { id: "josemiguelo.workspace-layout", section: "left", after: "evindor.keystroke" },
      { id: "tornikegomareli.spaces", section: "left", after: "josemiguelo.workspace-layout" },
      { id: "pomodoro-omarchy", section: "centerEnd", before: "omarchy.weather" },
      { id: "omarchy.elsewhen", section: "centerEnd", before: "pomodoro-omarchy" },
      { id: "io.github.sumdahl.media", section: "right", after: "omarchy.tray" },
      { id: "omarchy.power", section: "right", after: "omarchy.monitor" },
      { id: "josemiguelo.theme-mode", section: "right", before: "omarchy.tray" },
      { id: "omarchy.keyboard-layout", section: "right", before: "josemiguelo.theme-mode" },
      { id: "omarchy.clock", section: "center", at: 0 },
      // Stock, but listed: a stray drag on the bar drops it in another section,
      // and only a listed widget gets put back.
      { id: "omarchy.indicators", section: "centerBegin", at: 0 },
      ...(extra.widgets ?? []),
    ],
  }),
  omarchyKeystrokeWindows,
  omarchyPomodoro,
];
