// flatpak: the package itself and Flathub as a user-level remote
// (~/.local/share/flatpak). Every flatpak install `requires` both, so they
// come first.
import { flatpak, omarchy, program, requires, via } from "loadout";

// Omarchy doesn't ship it.
export const flatpakProgram = program("flatpak", {
  description: "flatpak app runtime",
  install: [
    // So a plan installing it may install flatpaks after it.
    via(omarchy, { provides: { flatpak: {  } } }),
  ],
});

// Flathub as a user-level remote, so flatpaks can depend on it.
export const flathubRemote = program("flathub-remote", {
  description: "flathub flatpak remote (user)",
  install: [
    // A remote, not an app: the probe comes from flatpak, the rest is its own.
    via(flatpak, {
        command: "flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo",
        present: "x=$(flatpak --user remotes --columns=name) && printf '%s\\n' \"$x\" | grep -qx flathub",
      }),
  ],
});

requires(flatpak, [flatpakProgram, flathubRemote]);
