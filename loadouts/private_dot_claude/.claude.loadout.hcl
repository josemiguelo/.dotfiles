# Claude Code: a self-updating binary from claude.ai/install.sh, not managed
# by a package manager; and the skills repo its sessions use.

program "claude" {
  description = "Claude Code CLI"

  custom {
    command = "curl -fsSL https://claude.ai/install.sh | bash"
  }

  # A fresh shell may not have ~/.local/bin on PATH yet.
  path    = ["$HOME/.local/bin"]
  version = "claude --version"

  # Is the binary behind the latest published release?
  updates_managed_by = ".loadout/outdated-claude.sh"
}

script "skills-repo" {
  description = "clone the skills repo (bare + worktree) and symlink its skills into ~/.claude/skills"
  managed_by  = ".loadout/skills-repo.sh"
}
