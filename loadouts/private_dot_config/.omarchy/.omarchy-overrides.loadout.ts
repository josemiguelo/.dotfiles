// Local replacements of Omarchy commands, first on the PATH of everything
// Hyprland starts. The scripts import .loadout/lib/.
import { script } from "loadout";

// Local replacements of Omarchy commands: `run: [omarchyCommandOverrides]`.
export const omarchyCommandOverrides = script("omarchy-command-overrides", {
  description: "local replacements of Omarchy commands come first",
  managedBy: ".loadout/omarchy-command-overrides.ts",
});

// `omarchy-brightness-keyboard off` saves 0 over the real level; the wrapper
// skips `off` on a dark light. Goes once Omarchy is fixed.
export const omarchyKeyboardBacklightGuard = script("omarchy-keyboard-backlight-guard", {
  description: "keyboard backlight comes back after sleep",
  managedBy: ".loadout/omarchy-keyboard-backlight-guard.ts",
  runAfter: [omarchyCommandOverrides],
});
