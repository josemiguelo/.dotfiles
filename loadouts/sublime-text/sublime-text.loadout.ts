import { program, withOmarchy } from "loadout";

// Versions are build numbers (4192).
export const sublimeText = program("sublime-text", {
  description: "Sublime Text editor",
  canBeInstalled: [
    // pacman's version is "4.<build>", which the dotted regex reads whole.
    withOmarchy({ packageName: "sublime-text-4" }),
  ],
});
