// Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys,
// each written into ~/.config/hypr/ as a managed block. The scripts use
// Hyprland's helpers (#hypr, in .loadout/lib/) and Omarchy's (#omarchy).
import { script } from "loadout";
import { omarchyPlugins } from "../omarchy/omarchy-shell.loadout.ts";

// Hyprland on Omarchy: settings, bindings, window sizes and app hotkeys:
// `run: [omarchyHarpoon]`.

// hypr-config/<file>.lua into ~/.config/hypr/<file>.lua, for the files the
// machine names.
export const omarchyHyprConfig = script("omarchy-hypr-config", {
  description: "Hyprland settings from hypr-config/*.lua",
  module: () => import("./.loadout/omarchy-hypr-config.ts"),
  rules: () => import("./.loadout/omarchy-hypr-config.rules.ts"),
});

export const omarchyCloseWindowKey = script("omarchy-close-window-key", { description: "SUPER+Q closes windows", module: () => import("./.loadout/omarchy-close-window-key.ts") });

// btop's window at the machine's size (pixels or a share: 80% 80%), not
// 875x600.
export const omarchyActivityMonitorSize = script("omarchy-activity-monitor-size", {
  description: "activity monitor (btop) window size",
  module: () => import("./.loadout/omarchy-activity-monitor-size.ts"),
  rules: () => import("./.loadout/omarchy-activity-monitor-size.rules.ts"),
});

// Hotkeys on Hyper, like Raycast's: jump to an app, or show a scratchpad
// workspace of its own (AI, Media, Social, Notes) on the window last used there;
// Omarchy's scratchpad on Hyper+Escape. The engine is
// github.com/josemiguelo/omarchy-harpoon, which omarchy-plugins installs.
export const omarchyHarpoon = script("omarchy-harpoon", {
  description: "Hyper+letter app and overlay hotkeys, the scratchpad on Hyper+Escape",
  module: () => import("./.loadout/omarchy-harpoon.ts"),
  runAfter: [omarchyPlugins],
});

// The machine's dark and light themes, for omarchy-theme-mode-toggle
// (Hyper+Enter).
export const omarchyThemeMode = script("omarchy-theme-mode", {
  description: "Hyper+Enter switches between the dark and light theme",
  module: () => import("./.loadout/omarchy-theme-mode.ts"),
  rules: () => import("./.loadout/omarchy-theme-mode.rules.ts"),
});
