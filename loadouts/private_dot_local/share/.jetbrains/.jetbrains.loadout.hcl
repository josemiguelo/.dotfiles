# JetBrains: the Toolbox app (it installs into ~/.local/share/JetBrains) and
# its launchers on PATH. IdeaVim's config is loadouts/dot_ideavimrc.

program "jetbrains-toolbox" {
  description = "JetBrains Toolbox"

  # Linux: per-user install from JetBrains' release feed (the script says
  # why not the ublue-os cask). Version = the build.txt Toolbox ships.
  custom "linux" {
    managed_by = ".loadout/install-toolbox.sh"
    regex      = "([0-9]+\\.[0-9][0-9.]*)"
  }

  via "brew-cask" { spare = "for macOS; no Mac installs it yet" }
}

script "link-jetbrains-launchers-linux" {
  description = "symlink JetBrains Toolbox launcher scripts into ~/.local/bin"
  managed_by  = ".loadout/link-launchers.sh"
  run_after   = [program.jetbrains-toolbox]
}
