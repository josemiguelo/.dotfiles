package loadouts

import loadout.dsl.*

/**
 * Every Fedora workstation: dnf (with its repos and COPRs) for system
 * packages, brew for what Fedora lags on, flatpak for a few apps. No machine
 * runs Fedora today; this keeps one ready.
 */
val fedora = profile(name = "fedora") {
    spare(reason = "no machine runs Fedora today; this keeps one ready")

    via(dnf) {
        install(setupDnf, dnfPluginsCore, curl, git, gcc, procpsNg, zsh, tmux)
        install(just, vim, vlc, anydesk)
        install(firefox, googleChromeStable)
    }
    install(fedoraBuildDeps)
    via(dnfCopr) {
        install(kitty, scrcpy)
    }
    via(dnfRepo) {
        install(googleCloudCli, code, antigravity, onePassword, slack, teamsForLinux, sublimeText)
    }
    via(flatpak) {
        install(flathubRemote, obsidian)
    }

    install(
        setupBrew.variant(name = "linux"),
        jetbrainsToolbox.variant(name = "linux"),
        tpack.variant(name = "linux"),
    )
    install(ngrok, claude, kotlinLsp)
    via(brew) {
        install(yazi, eza, atuin, gitDelta, chezmoi)
        install(yq, awscli, trashCli)
    }
    via(brewTap) {
        install(workmux)
    }

    run(Dotfiles.all)
    run(setupGit, defaultShell, nvimPlugins, downloadFonts, userEnvironment, unlinkBrewGlib)
    run(shellScripts)
    run(tmuxPlugins, removeBrewTmux)
    run(linkJetbrainsLaunchers, removeFirefoxFlatpak)
    run(skillsRepo, workmuxSetup)
}
