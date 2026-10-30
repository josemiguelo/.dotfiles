# tmux: the multiplexer, its plugin manager and plugins, and (on Omarchy)
# keeping kitty's palette across theme switches.

# On Omarchy a base package, mapped to Omarchy's installer so workmux resolves
# it without brew installing a second copy.
program "tmux" {
  install_via = [brew, dnf, omarchy]
}

program "tpack" {
  description = "tmux package manager"

  # macOS: a cask from its tap.
  via "brew-tap-cask" {
    params = { tap = "tmuxpack/tpack" }
  }

  # Linux: its GitHub release, since the cask pulls in brew's tmux and git,
  # which would shadow the system's. Its own copy only: a tpack on PATH may
  # still be the cask's, which remove-brew-tmux takes away after this.
  custom "linux" {
    installed_by = ".loadout/install-tpack.sh"
    version      = "$HOME/.local/bin/tpack --version"
  }
}

# The plugins tmux.conf declares, present as clones; and whether each clone is
# behind its GitHub tip.
script "tmux-plugins" {
  description        = "tmux plugins tmux.conf declares"
  managed_by         = ".loadout/plugins.sh"
  run_after          = [program.tmux, program.tpack]
  updates_managed_by = ".loadout/outdated-plugins.sh"
}

# Linux: brew's tpack cask gone, with the tmux and git it pulled in.
script "remove-brew-tmux" {
  description = "no tpack, tmux or git from brew (Linux has its own)"
  managed_by  = ".loadout/remove-brew-tmux.sh"
  run_after   = [program.tpack]
}

# Undoes omarchy-theme-set-tmux after each theme switch: tmux here follows
# kitty's palette.
script "omarchy-tmux-theme" {
  description = "tmux keeps kitty's palette across omarchy theme switches"
  managed_by  = ".loadout/omarchy-theme.sh"
  run_after   = [program.tmux]
}
