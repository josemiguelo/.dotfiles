// Google Cloud CLI: Homebrew's cask.
import { brewCask, program, via } from "loadout";

export const googleCloudCli = program("google-cloud-cli", {
  description: "Google Cloud CLI",
  later: "a large Homebrew install; nothing in setup needs it",
  install: [
    // Homebrew's cask downloads the Linux tarball on Linux; on Arch the CLI
    // is AUR-only.
    via(brewCask, { pkg: "gcloud-cli" }),
  ],
});
