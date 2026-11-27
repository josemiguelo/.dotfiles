// tmux: the multiplexer, its plugin manager and plugins, and (on Omarchy)
// keeping kitty's palette across theme switches.
import { program, script, withBrew, withCustomSteps, withOmarchy } from "loadout";
import { withBrewTapCask } from "../homebrew/homebrew.loadout.ts";

// On Omarchy a base package, mapped to Omarchy's installer so workmux resolves
// it without brew installing a second copy.
export const tmux = program("tmux", { canBeInstalled: [withBrew, withOmarchy] });

export const tpack = program("tpack", {
  description: "tmux package manager",
  canBeInstalled: [
    // macOS: a cask from its tap.
    withBrewTapCask({ tap: "tmuxpack/tpack" }),
    // Linux: its GitHub release, since the cask pulls in brew's tmux and git,
    // which would shadow the system's. Its own copy only: a tpack on PATH may
    // still be the cask's, which remove-brew-tmux takes away after this.
    withCustomSteps("linux", { module: () => import("./.loadout/install-tpack.ts"), versionCommand: "$HOME/.local/bin/tpack --version" }),
  ],
});

// The plugins tmux.conf declares, present as clones; and whether each clone is
// behind its GitHub tip.
export const tmuxPlugins = script("tmux-plugins", {
  description: "tmux plugins tmux.conf declares",
  module: () => import("./.loadout/plugins.ts"),
  runAfter: [tmux, tpack],
  updates: () => import("./.loadout/outdated-plugins.ts"),
});

// Linux: brew's tpack cask gone, with the tmux and git it pulled in.
export const removeBrewTmux = script("remove-brew-tmux", {
  description: "no tpack, tmux or git from brew (Linux has its own)",
  module: () => import("./.loadout/remove-brew-tmux.ts"),
  runAfter: [tpack],
});

// Undoes omarchy-theme-set-tmux after each theme switch: tmux here follows
// kitty's palette.
export const omarchyTmuxTheme = script("omarchy-tmux-theme", {
  description: "tmux keeps kitty's palette across omarchy theme switches",
  module: () => import("./.loadout/omarchy-theme.ts"),
  runAfter: [tmux],
});
