import { omarchy, program, script } from "loadout";

export const solaar = program("solaar", { description: "Logitech device manager", install: [omarchy] });

// Launched when wanted, not at every login.
export const solaarNoAutostart = script("solaar-no-autostart", {
  description: "remove solaar autostart entry",
  run: "sudo rm -f /etc/xdg/autostart/solaar.desktop",
  check: "test ! -f /etc/xdg/autostart/solaar.desktop",
  runAfter: [solaar],
});
