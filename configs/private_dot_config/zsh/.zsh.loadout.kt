// zsh: the shell, its plugins and completions, and the login shell. Its
// dotfiles are this directory plus ~/.zshenv, which points ZDOTDIR here.
package repo

import loadout.dsl.*

/** macOS ships zsh, so only Linux machines map it. */
val zsh = program(name = "zsh") {
    installVia(
        dnf,
        omarchy,
    )
}

// antidote and the bundles .zplugins declares, present as clones; and
// whether the antidote clone and its bundles are behind their GitHub tips.
val zshPlugins = script(
    name = "zsh-plugins",
    description = "antidote and the bundles .zplugins declares",
) {
    managedBy(".loadout/plugins.sh")
    runAfter(zsh)
    updatesManagedBy(".loadout/outdated-antidote.sh", name = "antidote")
    updatesManagedBy(".loadout/outdated-antidote-plugins.sh", name = "antidote-plugins")
}

val setupCompletions = script(
    name = "setup-completions",
    description = "shell completions",
) {
    managedBy(".loadout/completions.sh")
}

/** Flips only once zsh and ~/.zshenv are in place, so the first zsh login is never a bare one. Next login. */
val defaultShell = script(
    name = "default-shell",
    description = "login shell set to zsh",
) {
    managedBy(".loadout/default-shell.sh")
    needsSudo()
    runAfter(zsh)
}
