// ssh on Omarchy: the ssh server, set up Omarchy's way.
import { script } from "loadout";
import { githubSshKey } from "./.ssh.loadout.ts";

// sshd the Omarchy way (rate-limited ufw rule from private ranges, key-only
// logins); authorized_keys mirrors the account's keys with the named titles.
export const omarchySshd = script("omarchy-sshd", {
  description: "sshd with key-only logins for the trusted GitHub keys",
  managedBy: ".loadout/omarchy-sshd.ts",
  needsSudo: true,
  // gh logged in, with the scope that lists the account's keys.
  runAfter: [githubSshKey],
});
