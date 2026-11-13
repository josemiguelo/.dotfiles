// Antigravity: Google's IDE, from the AUR.
import { omarchyAur, program, via } from "loadout";

export const antigravity = program("antigravity", {
  description: "Antigravity IDE",
  later: "a large app download; nothing in setup needs it",
  install: [
    // Google's IDE tarball, repackaged; not the AUR's `antigravity` (2.0, a
    // different product).
    via(omarchyAur, { pkg: "antigravity-ide" }),
  ],
});
