import { program, withCustomSteps, withOmarchy, withOmarchyAur } from "loadout";

// pacman's package lists. Omarchy 4's offline ISO installs from the ISO's own
// repository and leaves pacman configured online without ever downloading
// the online lists: until they're synced, every `omarchy pkg add` (pacman -S,
// no -y) fails with "target not found". Synced by `omarchy update`: Omarchy's
// pacman hook refuses a direct `pacman -Syu`, and -y runs it unattended. It
// needs sudo's password without saying sudo.
export const omarchyPackageLists = program("omarchy-package-lists", {
  description: "pacman's package lists, synced by omarchy update",
  canBeInstalled: [
    withCustomSteps({
        installCommand: "omarchy update -y",
        isInstalled: "test -s /var/lib/pacman/sync/core.db && test -s /var/lib/pacman/sync/extra.db",
        needsSudo: true,
      }),
  ],
});

// Every install through Omarchy's installers needs the lists first.
withOmarchy.needs(omarchyPackageLists);

withOmarchyAur.needs(omarchyPackageLists);
