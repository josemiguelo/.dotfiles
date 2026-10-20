// Claude Code: a self-updating binary from claude.ai/install.sh, not managed
// by a package manager; and the skills repo its sessions use.
package repo

import loadout.dsl.*

val claude = program(
    name = "claude",
    description = "Claude Code CLI",
) {
    custom {
        command = "curl -fsSL https://claude.ai/install.sh | bash"
    }

    // A fresh shell may not have ~/.local/bin on PATH yet.
    path("\$HOME/.local/bin")
    version(command = "claude --version")

    // Is the binary behind the latest published release?
    updatesManagedBy("outdated-claude.sh")
}

val skillsRepo = script(
    name = "skills-repo",
    description = "clone the skills repo (bare + worktree) and symlink its skills into ~/.claude/skills",
) {
    managedBy("skills-repo.sh")
}
