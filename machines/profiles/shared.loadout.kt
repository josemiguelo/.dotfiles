// What several profiles share. Plain lists, not templates: each profile still
// says which installer moves them. Adding a shell tool is one line here, not
// one per profile.
package loadouts

import loadout.dsl.*

/** The shell tools every Omarchy and macOS machine has. */
val everydayCli = listOf(
    yazi, fzf, starship, atuin, bat, eza, btop, fd, gitDelta, gum,
    lazydocker, lazygit, ripgrep, treeSitterCli, zoxide,
)

val shellScripts = listOf(zshPlugins, setupCompletions)
