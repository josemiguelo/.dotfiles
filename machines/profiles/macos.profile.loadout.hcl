# Every macOS machine. macOS ships zsh as the login shell, so zsh is neither
# installed nor switched to.
profile "macos" {
  spare = "the work laptop extends it, from a private child repo of this one"

  install = [
    variant(program.setup-brew, "macos"),
    program.ngrok, program.claude, program.kotlin-lsp,
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
      program.obs,
    ]
  }
  via "brew-tap-cask" {
    install = [program.tpack, program.voxtype]
  }

  run = [
    local.dotfiles_all,
    script.setup-git, script.skills-repo, script.workmux-setup, script.nvim-plugins,
    script.download-fonts,
    local.shell_scripts,
    script.mise-tools, script.mise-default-packages, script.java-macos-integration,
    script.tmux-plugins,
    script.voxtype-setup,
  ]
}
