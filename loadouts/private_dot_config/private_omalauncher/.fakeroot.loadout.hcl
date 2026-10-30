# fakeroot where the real one can't run (omalauncher's proot on Android).

# The proot shim as /usr/local/bin/fakeroot, so checkupdates (pacman's
# outdated oracle) runs.
script "fakeroot-shim" {
  description = "a fakeroot that runs under proot, for checkupdates"
  run         = "install -m 755 .loadout/fakeroot /usr/local/bin/fakeroot"
  check       = "cmp -s .loadout/fakeroot /usr/local/bin/fakeroot"
}
