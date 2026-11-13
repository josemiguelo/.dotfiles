# Google Cloud CLI: Homebrew's cask.

program "google-cloud-cli" {
  description = "Google Cloud CLI"
  later       = "a large Homebrew install; nothing in setup needs it"

  # Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
  # is AUR-only.
  via "brew-cask" { pkg = "gcloud-cli" }
}
