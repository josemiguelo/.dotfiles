package loadouts

import loadout.dsl.*

/** Every Omarchy machine: Omarchy's own installer for system packages, brew only where no trustworthy Arch package exists. */
val omarchyProfile = profile(name = "omarchy") {
    data { omarchy = true }

    via(omarchy) {
        install(curl, git, gcc, procpsNg, zsh, chezmoi, mise, kitty, tmux)
        install(everydayCli)
        install(voxtype, code, sublimeText, obsidian, spotify, vlc, onePassword, onePasswordCli)
        install(ttfFiracodeNerd, wtype, zenity)
    }
    via(omarchyAur) {
        install(antigravity, slack, teamsForLinux, anydesk)
        install(voxtypeTui, brave)
    }

    install(
        setupBrew.variant(name = "linux"),
        jetbrainsToolbox.variant(name = "linux"),
        tpack.variant(name = "linux"),
    )
    install(ngrok, kotlinLsp)
    via(brew) {
        install(just, vim, scrcpy)
        install(awscli, trashCli, yq)
    }
    via(brewTap) {
        install(workmux)
    }
    via(brewCask) {
        install(googleCloudCli)
    }

    // claude comes from mise here (conf.d/omarchy.toml).
    run(Dotfiles.all)
    run(setupGit, skillsRepo, workmuxSetup, defaultShell, nvimPlugins, unlinkBrewGlib, keychronLauncherAccess)
    run(shellScripts)
    run(Mise.tools, Mise.defaultPackages)
    run(Mise.omarchyDefaultAgent, "claude")
    run(omarchyDefaultTerminal)
    run(tmuxPlugins, removeBrewTmux, omarchyTmuxTheme)
    run(linkJetbrainsLaunchers)

    // Hyprland
    run(Hyprland.config, "input", "looknfeel")
    run(Hyprland.closeWindowKey, Hyprland.googleBindings, Hyprland.harpoon)
    run(Hyprland.themeMode, "tokyo-night", "catppuccin-latte")

    omarchyBar()

    // Apps the Omarchy way
    run(Omarchy.onePassword, Omarchy.vscode, Omarchy.brave)
    run(Omarchy.defaultBrowser, "brave")
    run(Omarchy.agentsPrune, "claude", "codex", "gh", "gemini")

    // Web apps: Google's in HEY's place
    run(Webapps.remove, "Basecamp", "HEY")
    run(Webapps.gmail, Webapps.googleCalendar)

    run(Overrides.commands, Overrides.keyboardBacklightGuard)
    run(omarchyScreensaverBirds)
    // The screensaver gets ~14 minutes (it starts at 150s) before the lock.
    run(OmarchyShell.idle, "1000")
    run(Dictation.setup, Dictation.gpu)
}
