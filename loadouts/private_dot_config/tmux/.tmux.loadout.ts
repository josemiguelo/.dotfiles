// tmux: the multiplexer, its plugin manager and plugins, and (on Omarchy)
// keeping kitty's palette across theme switches.
import { brew, custom, omarchy, program, script, via } from "loadout";
import { brewTapCask } from "../.homebrew/.homebrew.loadout.ts";

// On Omarchy a base package, mapped to Omarchy's installer so workmux resolves
// it without brew installing a second copy.
export const tmux = program("tmux", { install: [brew, omarchy] });

export const tpack = program("tpack", {
  description: "tmux package manager",
  install: [
    // macOS: a cask from its tap.
    via(brewTapCask, { params: { tap: "tmuxpack/tpack" } }),
    // Linux: its GitHub release, since the cask pulls in brew's tmux and git,
    // which would shadow the system's. Its own copy only: a tpack on PATH may
    // still be the cask's, which remove-brew-tmux takes away after this.
    custom("linux", { installedBy: ".loadout/install-tpack.ts", version: "$HOME/.local/bin/tpack --version" }),
  ],
});

// The plugins tmux.conf declares, present as clones; and whether each clone is
// behind its GitHub tip.
export const tmuxPlugins = script("tmux-plugins", {
  description: "tmux plugins tmux.conf declares",
  managedBy: ".loadout/plugins.ts",
  runAfter: [tmux, tpack],
  updatesManagedBy: ".loadout/outdated-plugins.ts",
});

// Linux: brew's tpack cask gone, with the tmux and git it pulled in.
export const removeBrewTmux = script("remove-brew-tmux", {
  description: "no tpack, tmux or git from brew (Linux has its own)",
  managedBy: ".loadout/remove-brew-tmux.ts",
  runAfter: [tpack],
});

// Undoes omarchy-theme-set-tmux after each theme switch: tmux here follows
// kitty's palette.
export const omarchyTmuxTheme = script("omarchy-tmux-theme", {
  description: "tmux keeps kitty's palette across omarchy theme switches",
  managedBy: ".loadout/omarchy-theme.ts",
  runAfter: [tmux],
});
