# Antigravity: Google's IDE, from the AUR.

program "antigravity" {
  description = "Antigravity IDE"
  later       = "a large app download; nothing in setup needs it"

  # Google's IDE tarball, repackaged; not the AUR's `antigravity` (2.0, a
  # different product).
  via "omarchy-aur" { pkg = "antigravity-ide" }
}
