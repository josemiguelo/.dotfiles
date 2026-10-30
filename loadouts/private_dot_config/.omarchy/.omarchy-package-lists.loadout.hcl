# pacman's package lists. Omarchy 4's offline ISO installs from the ISO's own
# repository and leaves pacman configured online without ever downloading
# the online lists: until they're synced, every `omarchy pkg add` (pacman -S,
# no -y) fails with "target not found". Synced by `omarchy update`: Omarchy's
# pacman hook refuses a direct `pacman -Syu`, and -y runs it unattended. It
# needs sudo's password without saying sudo.
program "omarchy-package-lists" {
  description = "pacman's package lists, synced by omarchy update"

  custom {
    command    = "omarchy update -y"
    present    = "test -s /var/lib/pacman/sync/core.db && test -s /var/lib/pacman/sync/extra.db"
    needs_sudo = true
  }
}

# Every install through Omarchy's installers needs the lists first.
requires "omarchy" { programs = [program.omarchy-package-lists] }
requires "omarchy-aur" { programs = [program.omarchy-package-lists] }
