import { program, script, via } from "loadout";
import { brewTap } from "../.homebrew/.homebrew.loadout.ts";
import { tmux } from "../tmux/.tmux.loadout.ts";

// From its author's tap.
export const workmux = program("workmux", {
  description: "git worktrees + tmux windows for parallel agent sessions",
  dependsOn: [tmux],
  install: [via(brewTap, { params: { tap: "raine/workmux" } })],
});

// Reruns after every workmux upgrade, since one can change the hooks or
// skills.
export const workmuxSetup = script("workmux-setup", {
  description: "workmux's status-tracking hooks and skills for the agents here",
  managedBy: ".loadout/setup.ts",
  runAfter: [workmux],
});
