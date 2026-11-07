# Every macOS machine. macOS ships zsh as the login shell, so zsh is neither
# installed nor switched to.
profile "macos" {
  spare = "the work laptop extends it, from a private child repo of this one"

  install = [
    variant(program.setup-brew, "macos"),
    program.ngrok, program.claude,
  ]
  via "brew" {
    install = [
      local.everyday_cli,
      program.scrcpy, program.chezmoi, program.mise, program.tmux,
      program.awscli, program.trash-cli, program.yq, program.azure-cli, program.coreutils,
      program.gawk, program.gh, program.ghostscript, program.gnu-sed, program.jira-cli, program.jq,
      program.qemu, program.tree, program.unixodbc, program.wget, program.try,
    ]
  }
  via "brew-tap" {
    install = [program.workmux, program.terraform]
  }
  via "brew-cask" {
    install = [
      program.kitty, program["1password-cli"],
      program.raycast, program.codex, program.jordanbaird-ice, program.lunar, program.meetingbar,
      program.obs, program.superwhisper,
    ]
  }
  via "brew-tap-cask" {
    install = [program.tpack]
  }

  run = [
    local.dotfiles_all,
    script.setup-git, script.skills-repo, script.workmux-setup, script.nvim-plugins,
    script.mason-kotlin-lsp, script.remove-kotlin-lsp-download,
    script.download-fonts,
    local.shell_scripts,
    script.mise-tools, script.mise-default-packages, script.java-macos-integration,
    script.tmux-plugins,
  ]
}
