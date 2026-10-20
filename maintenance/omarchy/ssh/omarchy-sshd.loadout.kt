// ssh on Omarchy: the ssh server, set up Omarchy's way.
package repo

import loadout.dsl.*

/** sshd the Omarchy way (rate-limited ufw rule, key-only logins); authorized_keys mirrors the named GitHub user's. */
val omarchySshd = script(
    name = "omarchy-sshd",
    description = "sshd with key-only logins for the GitHub user's keys",
) {
    managedBy("omarchy-sshd.sh")
    needsSudo()
}
