// VS Code: Microsoft's repo on Fedora (.loadout/vscode.repo), Omarchy's build
// on Omarchy (set up by ../.omarchy's omarchy-vscode).
package loadouts

import loadout.dsl.*

val code = program(
    name = "code",
    description = "Visual Studio Code",
) {
    installVia(
        dnfRepo(repofile = file(".loadout/vscode.repo")),
        // Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
        omarchy(pkg = "visual-studio-code-bin"),
    )
}
