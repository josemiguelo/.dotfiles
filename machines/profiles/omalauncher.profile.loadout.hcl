# Arch inside the omalauncher Android launcher: proot, root, no systemd.
# Only what keeps the launcher's own configs in this repo, a snappy zsh, and
# mise with java, ruby and node (no other language): nothing else of the desktops.
#
# The rootfs ships without sudo, which pacman's installer runs: on a fresh
# install, `loadout --machine <name> install sudo` before setup-new-machine.
profile "omalauncher" {
  data = { omalauncher = true }

  install = [program.sudo, program.loadout, variant(program.mise, "mise-run")]
  via "pacman" {
    install = [
      program.git, program.chezmoi, program.gh, program.git-delta, program.pacman-contrib,
      program.zsh, program.zsh-autosuggestions, program.zsh-syntax-highlighting,
      program.zoxide, program.fzf, program.bat, program.eza, program.trash-cli,
      program.wl-clipboard,
    ]
  }

  run = [
    script.machine-name, script.fakeroot-shim,
    script.omalauncher-tracked, script.omalauncher-requires, script.omalauncher-layout,
    args(script.bare-repos, "loadout", "loadout.wiki"),
    script.skills-repo,
    ssh_key("id_ed25519"),
    local.dotfiles_all,
    script.setup-git,
    script.mise-tools,
    # The vault the launcher's vault-tasks widget reads; read only there, so
    # nothing here ever changes the phone's own copy, which TaskForge reads.
    script.obsidian-headless-sqlite,
    args(script.obsidian-sync, "jm", "~/Obsidian/vault", "pull-only"),
    script.default-shell,
  ]
}
