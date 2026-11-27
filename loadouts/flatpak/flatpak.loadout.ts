// flatpak: the package itself and Flathub as a user-level remote
// (~/.local/share/flatpak). Every flatpak install `requires` both, so they
// come first.
import { program, withFlatpak, withOmarchy } from "loadout";

// Omarchy doesn't ship it.
export const flatpakProgram = program("flatpak", {
  description: "flatpak app runtime",
  canBeInstalled: [
    // So a plan installing it may install flatpaks after it.
    withOmarchy({ addsToPath: { flatpak: true } }),
  ],
});

// Flathub as a user-level remote, so flatpaks can depend on it.
export const flathubRemote = program("flathub-remote", {
  description: "flathub flatpak remote (user)",
  canBeInstalled: [
    // A remote, not an app: its neededBinary comes from flatpak, the rest is its own.
    withFlatpak({
        installCommand: "flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo",
        isInstalled: "x=$(flatpak --user remotes --columns=name) && printf '%s\\n' \"$x\" | grep -qx flathub",
      }),
  ],
});

withFlatpak.needs(flatpakProgram, flathubRemote);
