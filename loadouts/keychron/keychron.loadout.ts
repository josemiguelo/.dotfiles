import { script } from "loadout";

// Keychron HID nodes open to the logged-in user (udev uaccess), so the
// Launcher (WebHID) connects: the rule is in root/, which loadout applies
// before the scripts; this applies it to a Keychron already plugged in.
export const keychronLauncherAccess = script("keychron-launcher-access", {
  description: "Keychron Launcher can reach the keyboard (WebHID)",
  module: () => import("./.loadout/launcher-access.ts"),
  needsSudo: true,
});
