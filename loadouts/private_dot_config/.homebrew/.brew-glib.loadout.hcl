# Linux: brew's glib unlinked, so the system's gsettings, gio and gdbus are
# the ones on PATH. Later: glib comes with brew installs (scrcpy's ffmpeg and
# SDL), the large ones later themselves, so it unlinks after every program.
script "unlink-brew-glib" {
  description = "brew's glib unlinked (the system's gsettings reaches dconf)"
  later       = "glib comes with later brew installs (scrcpy); it unlinks after all of them"
  managed_by  = ".loadout/unlink-brew-glib.sh"
  run_after   = [program.scrcpy]
}
