// Claude Code: a self-updating binary from claude.ai/install.sh, not managed
// by a package manager; and the skills repo its sessions use.
import { custom, program, script } from "loadout";

export const claude = program("claude", {
  description: "Claude Code CLI",
  install: [custom({ command: "curl -fsSL https://claude.ai/install.sh | bash" })],
  // A fresh shell may not have ~/.local/bin on PATH yet.
  path: ["$HOME/.local/bin"],
  version: "claude --version",
  // Is the binary behind the latest published release?
  updatesManagedBy: ".loadout/outdated-claude.ts",
});

export const skillsRepo = script("skills-repo", {
  description: "clone the skills repo (bare + worktree) and symlink its skills into ~/.claude/skills",
  managedBy: ".loadout/skills-repo.ts",
});
