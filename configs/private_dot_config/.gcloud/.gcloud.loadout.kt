// Google Cloud CLI: dnf from Google's repo (.loadout/), a cask elsewhere.
package loadouts

import loadout.dsl.*

val googleCloudCli = program(
    name = "google-cloud-cli",
    description = "Google Cloud CLI",
) {
    installVia(
        dnfRepo(repofile = file(".loadout/google-cloud-cli.repo")),
        // Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
        // is AUR-only.
        brewCask(pkg = "gcloud-cli"),
    )
}
