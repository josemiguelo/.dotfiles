# Every Omarchy machine: Omarchy's own installer for system packages, brew
# where Arch's package lags behind (trash-cli, awscli, vim) or is another
# tool under the same name (Arch's yq is kislyuk's, not mikefarah's).
profile "omarchy" {
  data = { omarchy = true }

  via "omarchy" {
    install = [
      program.curl, program.git, program.gcc, program.procps-ng, program.zsh, program.chezmoi,
      program.mise, program.kitty, program.tmux,
      local.everyday_cli,
      program.voxtype, program.code, program.sublime-text, program.obsidian, program.spotify,
      program.vlc, program["1password"], program["1password-cli"],
      program.ttf-firacode-nerd, program.wtype, program.zenity, program.ghostscript,
      program.flatpak,
    ]
  }
  via "flatpak" {
    install = [program.flathub-remote, program.stremio]
  }
  via "omarchy-aur" {
    install = [
      program.antigravity, program.slack, program.teams-for-linux, program.anydesk,
      program.voxtype-tui, program.brave,
    ]
  }

  install = [
    program.omarchy-package-lists,
    variant(program.setup-brew, "linux"),
    variant(program.jetbrains-toolbox, "linux"),
    variant(program.tpack, "linux"),
    program.ngrok,
    program.kotlin-lsp,
  ]
  via "brew" {
    install = [
      program.just, program.vim, program.scrcpy,
      program.awscli, program.trash-cli, program.yq,
    ]
  }
  via "brew-tap" {
    install = [program.workmux]
  }
  via "brew-cask" {
    install = [program.google-cloud-cli]
  }

  run = [
    # claude comes from mise here (conf.d/omarchy.toml).
    local.dotfiles_all,
    script.setup-git, script.skills-repo, script.workmux-setup, script.default-shell,
    script.nvim-plugins, script.unlink-brew-glib, script.keychron-launcher-access,
    local.shell_scripts,
    script.mise-tools, script.mise-default-packages,
    args(script.omarchy-default-agent, "claude"),
    script.omarchy-default-terminal,
    script.tmux-plugins, script.remove-brew-tmux, script.omarchy-tmux-theme,
    script.link-jetbrains-launchers-linux,

    # Hyprland
    args(script.omarchy-hypr-config, "input", "looknfeel"),
    script.omarchy-close-window-key, script.omarchy-google-bindings, script.omarchy-harpoon,
    args(script.omarchy-theme-mode, "tokyo-night", "catppuccin-latte"),

    omarchy_bar(),

    # Apps the Omarchy way
    script.omarchy-1password, script.omarchy-vscode, script.omarchy-brave,
    args(script.omarchy-default-browser, "brave"),
    script.surfingkeys, script.surfingkeys-split-view,
    args(script.omarchy-agents-prune, "claude", "codex", "gh", "gemini"),

    # Web apps: Google's in HEY's place
    args(script.omarchy-webapps-remove, "Basecamp", "HEY"),
    script.omarchy-webapp-gmail, script.omarchy-webapp-google-calendar, script.omarchy-webapp-claude,

    script.omarchy-command-overrides, script.omarchy-keyboard-backlight-guard,
    # The screensaver gets ~14 minutes (it starts at 150s) before the lock.
    args(script.omarchy-idle, "1000"),
    script.omarchy-dictation, script.omarchy-dictation-gpu,
  ]
}
