# What several profiles share. Plain lists, not templates: each profile
# still says which installer moves them. Adding a shell tool is one line
# here, not one per profile.
locals {
  # The shell tools every Omarchy and macOS machine has.
  everyday_cli = [
    program.yazi, program.fzf, program.starship, program.atuin, program.bat, program.eza,
    program.btop, program.fd, program.git-delta, program.gum, program.lazydocker,
    program.lazygit, program.ripgrep, program.tree-sitter-cli, program.zoxide,
  ]

  shell_scripts = [script.zsh-plugins, script.setup-completions]
}
