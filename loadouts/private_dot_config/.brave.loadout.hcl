# The AUR's brave-bin (Brave's own build, repackaged), what Omarchy's
# `omarchy install browser brave` adds. The omarchy-brave script runs that
# installer for Omarchy's policy, flags and theme.
program "brave" {
  description = "Brave browser"
  via "omarchy-aur" { pkg = "brave-bin" }
}
