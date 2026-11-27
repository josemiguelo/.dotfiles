import { program, script } from "loadout";
import { withBrewTap } from "../homebrew/homebrew.loadout.ts";
import { miseToolsLater } from "../mise/mise.loadout.ts";
import { tmux } from "../tmux/tmux.loadout.ts";

// From its author's tap.
export const workmux = program("workmux", {
  description: "git worktrees + tmux windows for parallel agent sessions",
  dependsOn: [tmux],
  canBeInstalled: [withBrewTap({ tap: "raine/workmux" })],
});

// Reruns after every workmux upgrade, since one can change the hooks or
// skills. After every mise tool: it runs OpenCode, which Omarchy's mise
// installs on first use against a node version only mise-tools-later brings.
export const workmuxSetup = script("workmux-setup", {
  description: "workmux's status-tracking hooks and skills for the agents here",
  module: () => import("./.loadout/setup.ts"),
  runAfter: [workmux, miseToolsLater],
  canWait: "agent hooks and skills, after the mise tools OpenCode installs against",
});
