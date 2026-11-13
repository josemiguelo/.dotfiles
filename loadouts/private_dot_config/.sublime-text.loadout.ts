import { omarchy, program, via } from "loadout";

// Versions are build numbers (4192).
export const sublimeText = program("sublime-text", {
  description: "Sublime Text editor",
  install: [
    // pacman's version is "4.<build>", which the dotted regex reads whole.
    via(omarchy, { pkg: "sublime-text-4" }),
  ],
});
