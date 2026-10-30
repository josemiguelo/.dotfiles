# Antigravity: Google's repo on Fedora (.loadout/antigravity.repo), the AUR
# elsewhere.

program "antigravity" {
  description = "Antigravity IDE"

  via "dnf-repo" {
    params = { repofile = file(".loadout/antigravity.repo") }
  }

  # Google's IDE tarball, repackaged; not the AUR's `antigravity` (2.0, a
  # different product).
  via "omarchy-aur" { pkg = "antigravity-ide" }
}
