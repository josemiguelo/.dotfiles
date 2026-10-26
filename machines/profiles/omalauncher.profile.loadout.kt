package loadouts

import loadout.dsl.*

/**
 * Arch inside the omalauncher Android launcher: proot, root, no systemd.
 * Only what keeps the launcher's own configs in this repo, a snappy zsh, and
 * mise with java, ruby and node (no other language): nothing else of the desktops.
 *
 * The rootfs ships without sudo, which pacman's installer runs: on a fresh
 * install, `loadout --machine <name> install sudo` before setup-new-machine.
 */
val omalauncherProfile = profile(name = "omalauncher") {
    data { omalauncher = true }

    install(sudo, loadoutCli, mise.variant(name = "mise-run"))
    via(pacman) {
        install(git, chezmoi, gh, gitDelta, pacmanContrib)
        install(zsh, zshAutosuggestions, zshSyntaxHighlighting)
        install(zoxide, fzf, bat, eza, trashCli, wlClipboard)
    }

    run(machineName, fakerootShim)
    run(omalauncherTracked, omalauncherRequires, omalauncherLayout)
    run(bareRepos, "loadout", "loadout.wiki")
    run(skillsRepo)
    sshKey("id_ed25519")
    run(Dotfiles.all)
    run(setupGit)
    run(Mise.tools)
    // The vault the launcher's vault-tasks widget reads; read only there, so
    // nothing here ever changes the phone's own copy, which TaskForge reads.
    run(Obsidian.headlessSqlite)
    run(
        Obsidian.sync,
        "jm",
        "~/Obsidian/vault",
        "pull-only",
    )
    run(defaultShell)
}
