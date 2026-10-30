# Every Fedora workstation: dnf (with its repos and COPRs) for system
# packages, brew for what Fedora lags on, flatpak for a few apps. No machine
# runs Fedora today; this keeps one ready.
profile "fedora" {
  spare = "no machine runs Fedora today; this keeps one ready"

  via "dnf" {
    install = [
      program.setup-dnf, program.dnf-plugins-core, program.curl, program.git, program.gcc,
      program.procps-ng, program.zsh, program.tmux,
      program.just, program.vim, program.vlc, program.anydesk,
      program.firefox, program.google-chrome-stable, program.flatpak,
      local.fedora_build_deps,
    ]
  }
  via "dnf-copr" {
    install = [program.kitty, program.scrcpy]
  }
  via "dnf-repo" {
    install = [
      program.google-cloud-cli, program.code, program.antigravity, program["1password"],
      program.slack, program.teams-for-linux, program.sublime-text,
    ]
  }
  via "flatpak" {
    install = [program.flathub-remote, program.obsidian]
  }

  install = [
    variant(program.setup-brew, "linux"),
    variant(program.jetbrains-toolbox, "linux"),
    variant(program.tpack, "linux"),
    program.ngrok,
    program.claude,
    program.kotlin-lsp,
  ]
  via "brew" {
    install = [
      program.yazi, program.eza, program.atuin, program.git-delta, program.chezmoi,
      program.yq, program.awscli, program.trash-cli,
    ]
  }
  via "brew-tap" {
    install = [program.workmux]
  }

  run = [
    local.dotfiles_all,
    script.setup-git, script.default-shell, script.nvim-plugins, script.download-fonts,
    script.user-environment, script.unlink-brew-glib,
    local.shell_scripts,
    script.tmux-plugins, script.remove-brew-tmux,
    script.link-jetbrains-launchers-linux, script.remove-firefox-flatpak,
    script.skills-repo, script.workmux-setup,
  ]
}
