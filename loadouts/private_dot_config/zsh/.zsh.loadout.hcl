# zsh: the shell, its plugins and completions, and the login shell. Its
# dotfiles are this directory plus ~/.zshenv, which points ZDOTDIR here.

# macOS ships zsh, so only Linux machines map it.
program "zsh" {
  install_via = [dnf, omarchy]
}

# antidote and the bundles .zplugins declares, present as clones; and
# whether the antidote clone and its bundles are behind their GitHub tips.
script "zsh-plugins" {
  description = "antidote and the bundles .zplugins declares"
  managed_by  = ".loadout/plugins.ts"
  run_after   = [program.zsh]

  outdated {
    name    = "antidote"
    command = run_script(".loadout/outdated-antidote.ts")
    upgrade = run_script(".loadout/outdated-antidote.ts update {item}")
  }

  outdated {
    name    = "antidote-plugins"
    command = run_script(".loadout/outdated-antidote-plugins.ts")
    upgrade = run_script(".loadout/outdated-antidote-plugins.ts update {item}")
  }
}

script "setup-completions" {
  description = "shell completions"
  managed_by  = ".loadout/completions.ts"
}

# Flips only once zsh and ~/.zshenv are in place, so the first zsh login is
# never a bare one. Next login.
script "default-shell" {
  description = "login shell set to zsh"
  managed_by  = ".loadout/default-shell.sh"
  needs_sudo  = true
  run_after   = [program.zsh]
}
