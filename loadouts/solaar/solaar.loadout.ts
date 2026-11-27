import { program, script, withOmarchy } from "loadout";

export const solaar = program("solaar", { description: "Logitech device manager", canBeInstalled: [withOmarchy] });

// Launched when wanted, not at every login.
export const solaarNoAutostart = script("solaar-no-autostart", {
  description: "remove solaar autostart entry",
  runCommand: "sudo rm -f /etc/xdg/autostart/solaar.desktop",
  checkCommand: "test ! -f /etc/xdg/autostart/solaar.desktop",
  runAfter: [solaar],
});
