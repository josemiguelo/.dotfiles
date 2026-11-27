// Google Cloud CLI: Homebrew's cask.
import { program, withBrewCask } from "loadout";

export const googleCloudCli = program("google-cloud-cli", {
  description: "Google Cloud CLI",
  canWait: "a large Homebrew install; nothing in setup needs it",
  canBeInstalled: [
    // Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
    // is AUR-only.
    withBrewCask({ packageName: "gcloud-cli" }),
  ],
});
