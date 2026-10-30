# Linux: brew's glib unlinked, so the system's gsettings, gio and gdbus are
# the ones on PATH.
script "unlink-brew-glib" {
  description = "brew's glib unlinked (the system's gsettings reaches dconf)"
  managed_by  = ".loadout/unlink-brew-glib.sh"
}
