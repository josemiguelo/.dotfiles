// Apps set up the Omarchy way. The apps themselves are programs; the
// scripts source ../lib/.
package loadouts

import loadout.dsl.*

/**
 * Omarchy's own setup of apps the machine installs: `run(Omarchy.brave)`.
 * Inside, `brave` is this setup; the app is `loadouts.brave`.
 */
object Omarchy {
    /** Omarchy's installer (Chromium extension entry), started unscaled at login, Ctrl+Shift+Space for Quick Access. */
    val onePassword = script(
        name = "omarchy-1password",
        description = "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access",
    ) {
        managedBy("omarchy-1password.sh")
        runAfter(loadouts.onePassword, onePasswordCli)
    }

    val brave = script(
        name = "omarchy-brave",
        description = "Brave, set up by Omarchy's browser installer",
    ) {
        managedBy("omarchy-brave.sh")
        needsSudo()
        runAfter(loadouts.brave)
    }

    /** The default browser, named by the machine: `run(Omarchy.defaultBrowser, "brave")`. */
    val defaultBrowser = script(
        name = "omarchy-default-browser",
        description = "Omarchy's default browser",
    ) {
        file("omarchy-default-browser-arch.sh")
        check("test \"\$(omarchy default browser)\" = \"\$1\"")
        runAfter(loadouts.brave, brave)
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

    /** Omarchy's agent launchers (~/.local/bin) and seeded configs (~/.config), pruned to the agents the machine names. */
    val agentsPrune = script(
        name = "omarchy-agents-prune",
        description = "only the Omarchy agent launchers and configs in use",
    ) {
        managedBy("omarchy-agents-prune.sh")
    }
}
