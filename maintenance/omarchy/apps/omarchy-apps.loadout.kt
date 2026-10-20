// Apps set up the Omarchy way. The apps themselves are programs; the
// scripts source ../lib/.
package repo

import loadout.dsl.*

/**
 * Omarchy's own setup of apps the machine installs: `run(Omarchy.brave)`.
 * Inside, `brave` is this setup; the app is `repo.brave`.
 */
object Omarchy {
    /** Omarchy's installer (Chromium extension entry), started unscaled at login, Ctrl+Shift+Space for Quick Access. */
    val onePassword = script(
        name = "omarchy-1password",
        description = "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access",
    ) {
        managedBy("omarchy-1password.sh")
        runAfter(repo.onePassword, onePasswordCli)
    }

    val brave = script(
        name = "omarchy-brave",
        description = "Brave, set up by Omarchy's browser installer",
    ) {
        managedBy("omarchy-brave.sh")
        needsSudo()
        runAfter(repo.brave)
    }

    /** The default browser, named by the machine: `run(Omarchy.defaultBrowser, "brave")`. */
    val defaultBrowser = script(
        name = "omarchy-default-browser",
        description = "Omarchy's default browser",
    ) {
        file("omarchy-default-browser-arch.sh")
        check("test \"\$(omarchy default browser)\" = \"\$1\"")
        runAfter(repo.brave, brave)
    }

    /** Omarchy's installer (keyring, no self-update, its theme); overwrites settings.json and opens VS Code once. */
    val vscode = script(
        name = "omarchy-vscode",
        description = "VS Code, set up by Omarchy's installer",
    ) {
        managedBy("omarchy-vscode.sh")
        runAfter(code)
    }

    /** docker group membership: root-equivalent, so opted into per machine. */
    val sudolessDocker = script(
        name = "omarchy-sudoless-docker",
        description = "sudoless Docker (user in the docker group)",
    ) {
        managedBy("omarchy-sudoless-docker.sh")
        needsSudo()
        runAfter(lazydocker)
    }

    /** Omarchy's ~/.local/bin agent launchers, pruned to the ones the machine names. */
    val agentLaunchersPrune = script(
        name = "omarchy-agent-launchers-prune",
        description = "only the Omarchy agent launchers in use",
    ) {
        managedBy("omarchy-agent-launchers-prune.sh")
    }
}
