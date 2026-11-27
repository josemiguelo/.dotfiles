import { program, script, withOmarchy } from "loadout";

export const git = program("git", { canBeInstalled: [withOmarchy] });

// Identity and delta as pager, written into ~/.gitconfig (not a chezmoi file).
export const setupGit = script("setup-git", { description: "git identity and delta configuration", module: () => import("./.loadout/setup-git.ts") });
