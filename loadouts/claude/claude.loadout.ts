// Claude Code: a self-updating binary from claude.ai/install.sh, not managed
// by a package manager; and the skills repo its sessions use.
import { program, script, withCustomSteps } from "loadout";

export const claude = program("claude", {
  description: "Claude Code CLI",
  canBeInstalled: [withCustomSteps({ installCommand: "curl -fsSL https://claude.ai/install.sh | bash" })],
  // A fresh shell may not have ~/.local/bin on PATH yet.
  searchPath: ["$HOME/.local/bin"],
  versionCommand: "claude --version",
  // Is the binary behind the latest published release?
  updates: () => import("./.loadout/outdated-claude.ts"),
});

export const skillsRepo = script("skills-repo", {
  description: "clone the skills repo (bare + worktree) and symlink its skills into ~/.claude/skills",
  module: () => import("./.loadout/skills-repo.ts"),
});
