import { script } from "loadout";

// Keychron HID nodes open to the logged-in user (udev uaccess), so the
// Launcher (WebHID) connects.
export const keychronLauncherAccess = script("keychron-launcher-access", {
  description: "Keychron Launcher can reach the keyboard (WebHID)",
  managedBy: ".loadout/launcher-access.ts",
  needsSudo: true,
});
