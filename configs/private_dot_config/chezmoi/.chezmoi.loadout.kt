// chezmoi: the dotfiles manager and its checkout (this repo). loadout
// applies the dotfiles itself; these scripts watch the checkout's git side.
package repo

import loadout.dsl.*

val chezmoi = program(name = "chezmoi") {
    installVia(
        brew,
        omarchy,
    )
}

private const val CHECKOUT = "$HOME/.local/share/chezmoi"
private const val HTTPS = "https://github.com/josemiguelo/.dotfiles.git"
private const val SSH = "git@github.com:josemiguelo/.dotfiles.git"

/** The dotfiles checkout's git side: `run(Dotfiles.pull)`. */
object Dotfiles {
    // Pulls over https, pushes over ssh: the repo is public, so pulling works
    // before GitHub knows this machine's key (github-ssh-key).
    val sshRemote = script(
        name = "dotfiles-ssh-remote",
        description = "point the chezmoi checkout's pushes at the ssh dotfiles remote",
    ) {
        run(
            "git -C $CHECKOUT remote set-url origin $HTTPS",
            "git -C $CHECKOUT config remote.origin.pushurl $SSH",
        )
        check(
            "test \"\$(git -C $CHECKOUT config --get remote.origin.url)\" = $HTTPS",
            "test \"\$(git -C $CHECKOUT config --get remote.origin.pushurl)\" = $SSH",
        )
    }

    /** Is the local source behind origin? (throttled fetch, fail-soft offline). Converge = pull only. */
    val pull = script(
        name = "dotfiles-pull",
        description = "pull dotfiles source when behind its origin",
    ) {
        managedBy(".loadout/pull.sh")
        maintainOnly()
    }

    /** Local edits origin hasn't seen. After the pull, so one run rebases before it pushes. */
    val push = script(
        name = "dotfiles-push",
        description = "push dotfiles source when ahead of its origin",
    ) {
        managedBy(".loadout/push.sh")
        runAfter(pull)
        maintainOnly()
    }

    /** What every machine runs for its dotfiles checkout: `run(Dotfiles.all)`. */
    val all = listOf(pull, push, sshRemote)
}
