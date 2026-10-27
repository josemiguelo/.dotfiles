// ssh: this machine's key and agent, on any OS. (Omarchy's ssh server is
// maintenance/omarchy/ssh.)
package loadouts

import loadout.dsl.*

val setupSsh = script(
    name = "setup-ssh",
    description = "machine ssh key and agent auto-add config",
) {
    file("setup-ssh.sh")
    // The agent-unit clause is for Linux with systemd; uname short-circuits it
    // on macOS, and /run/systemd/system where systemd isn't running (omalauncher's proot).
    check(
        "test -f $HOME/.ssh/\$1",
        "grep -q 'AddKeysToAgent yes' $HOME/.ssh/config",
        "test \"\$(uname -s)\" != Linux || test ! -d /run/systemd/system || systemctl --user -q is-enabled ssh-agent.socket",
    )
}

/** The key on GitHub, titled with the machine's name. Logs gh in through the browser when needed: the one browser step, last. */
val githubSshKey = script(
    name = "github-ssh-key",
    description = "this machine's ssh key on GitHub",
) {
    managedBy("github-ssh-key.sh")
    runAfter(setupSsh, Mise.tools, gh)
}

/**
 * The machine's key, on disk and on GitHub: one call instead of the same
 * two `run`s in every machine that has a key.
 */
fun MachineScope.sshKey(name: String) {
    run(setupSsh, name)
    run(githubSshKey, name)
}
