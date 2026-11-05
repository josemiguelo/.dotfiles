# Intentional's desktop guard (github.com/josemiguelo/intentional): group
# budgets for apps and sites on Hyprland, measured and enforced by a daemon
# (a systemd user service) and its Brave extension. Its groups live in
# ~/.config/intentional/groups.json, kept out of this repo.

# The latest GitHub release, installed by the install.sh it carries; no
# checkout, JDK or Kotlin/Native needed. The daemon links libcrypt.so.1.
program "intentional" {
  description = "Intentional's desktop guard: app and site budgets (Hyprland + Brave)"
  depends_on  = [program.libxcrypt-compat, program.brave]

  custom {
    managed_by = ".loadout/intentional.sh"
    # Its check prints "intentional <version>" once everything is in place.
    regex = "intentional ([0-9][0-9.]*)"
  }

  path               = ["$HOME/.local/bin"]
  version            = "intentional --version"
  updates_managed_by = ".loadout/outdated-intentional.sh"
}
