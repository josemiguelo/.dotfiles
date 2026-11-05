# Intentional's desktop guard (github.com/josemiguelo/intentional): group
# budgets for apps and sites on Hyprland, measured and enforced by a daemon
# (a systemd user service) and its Brave extension. Its groups live in
# ~/.config/intentional/groups.json, kept out of this repo.

# Built and installed from an Intentional checkout by the repo's own
# desktop/install.sh, which knows every piece (binary, unit, extension,
# native-messaging manifest, the brave-flags.conf line); this only finds it.
program "intentional" {
  description = "Intentional's desktop guard: app and site budgets (Hyprland + Brave)"
  depends_on  = [program.libxcrypt-compat, program.brave]

  custom {
    managed_by = ".loadout/intentional.sh"
  }

  path    = ["$HOME/.local/bin"]
  version = "intentional --version"
}
