import { script } from "loadout";
import { scrcpy } from "../scrcpy/scrcpy.loadout.ts";

// Linux: brew's glib unlinked, so the system's gsettings, gio and gdbus are
// the ones on PATH. Later: glib comes with brew installs (scrcpy's ffmpeg and
// SDL), the large ones later themselves, so it unlinks after every program.
export const unlinkBrewGlib = script("unlink-brew-glib", {
  description: "brew's glib unlinked (the system's gsettings reaches dconf)",
  canWait: "glib comes with later brew installs (scrcpy); it unlinks after all of them",
  module: () => import("./.loadout/unlink-brew-glib.ts"),
  runAfter: [scrcpy],
});
