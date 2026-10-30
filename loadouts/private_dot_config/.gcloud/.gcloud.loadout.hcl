# Google Cloud CLI: dnf from Google's repo (.loadout/), a cask elsewhere.

program "google-cloud-cli" {
  description = "Google Cloud CLI"

  via "dnf-repo" {
    params = { repofile = file(".loadout/google-cloud-cli.repo") }
  }

  # Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
  # is AUR-only.
  via "brew-cask" { pkg = "gcloud-cli" }
}
