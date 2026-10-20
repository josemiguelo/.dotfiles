package repo

import loadout.dsl.*

/**
 * Every Fedora workstation: dnf (with its repos and COPRs) for system
 * packages, brew for what Fedora lags on, flatpak for a few apps. No machine
 * runs Fedora today; this keeps one ready.
 */
val fedora = profile(name = "fedora") {
    install(dnf, setupDnf, dnfPluginsCore, curl, git, gcc, procpsNg, zsh, tmux)
    install(fedoraBuildDeps)
    install(dnf, just, vim, vlc)
    install(firefox, googleChromeStable) // dnf, their only variant
    install(dnf, anydesk)
    install(dnfCopr, kitty, scrcpy)
    install(dnfRepo, googleCloudCli, code, antigravity, onePassword, slack, teamsForLinux, sublimeText)
    install(flatpak, flathubRemote, obsidian)

    install(
        setupBrew.variant(name = "linux"),
        jetbrainsToolbox.variant(name = "linux"),
        tpack.variant(name = "linux"),
    )
    install(ngrok, claude)
    install(brew, yazi, eza, atuin, gitDelta, chezmoi)
    install(workmux, yq, awscli, trashCli) // brew, their only variant

    run(Dotfiles.all)
    run(setupGit, defaultShell, nvimPlugins, downloadFonts, userEnvironment, unlinkBrewGlib)
    run(shellScripts)
    run(tmuxPlugins, removeBrewTmux)
    run(linkJetbrainsLaunchers, removeFirefoxFlatpak)
    run(skillsRepo)
}
