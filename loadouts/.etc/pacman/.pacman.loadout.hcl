# sudo where a rootfs ships without it (omalauncher's Arch): the built-in
# pacman installer runs `sudo pacman`, and loadout asks `sudo -n true` before
# any step that needs it. Root never needs a password.

# Installed by root itself, since pacman's installer needs sudo already. A
# script, not a command line: a command naming the package `sudo` reads as
# one that runs sudo, and asks for it first.
#
# loadout asks for sudo before it installs anything, so on a fresh machine
# `loadout install sudo` goes first, then `setup-new-machine`.
program "sudo" {
  # pacman's variant: its check, probe and checkupdates oracle come from the
  # installer; only the install is root's own. The regex keeps the p-level
  # (1.9.16.p2) the default would cut, and is unanchored: it reads both
  # `pacman -Q sudo` and checkupdates' bare candidate (1.9.17.p3-1). Exempt
  # from the rule below: a program never requires itself.
  via "pacman" {
    installed_by = ".loadout/install-sudo.sh"
    regex        = "([0-9][0-9.p]*[0-9])"
  }
}

# every pacman install runs sudo
requires "pacman" { programs = [program.sudo] }

# checkupdates, the pacman installer's outdated oracle: without it `loadout
# outdated` finds nothing there.
program "pacman-contrib" {
  install_via = [pacman]
}
