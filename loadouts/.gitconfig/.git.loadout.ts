import { omarchy, program, script } from "loadout";

export const git = program("git", { install: [omarchy] });

// Identity and delta as pager, written into ~/.gitconfig (not a chezmoi file).
export const setupGit = script("setup-git", { description: "git identity and delta configuration", managedBy: ".loadout/setup-git.ts" });
