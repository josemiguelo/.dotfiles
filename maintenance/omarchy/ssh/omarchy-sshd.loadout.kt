// ssh on Omarchy: the ssh server, set up Omarchy's way.
package loadouts

import loadout.dsl.*

/** sshd the Omarchy way (rate-limited ufw rule from private ranges, key-only logins); authorized_keys mirrors the account's keys with the named titles. */
val omarchySshd = script(
    name = "omarchy-sshd",
    description = "sshd with key-only logins for the trusted GitHub keys",
) {
    managedBy("omarchy-sshd.sh")
    needsSudo()
    // gh logged in, with the scope that lists the account's keys.
    runAfter(githubSshKey)
}
