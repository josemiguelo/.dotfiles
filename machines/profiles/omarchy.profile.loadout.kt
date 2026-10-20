package repo

import loadout.dsl.*

/** Every Omarchy machine: Omarchy's own installer for system packages, brew only where no trustworthy Arch package exists. */
val omarchyProfile = profile(name = "omarchy") {
    data { omarchy = true }

    install(omarchy, curl, git, gcc, procpsNg, zsh, chezmoi, mise, kitty, tmux)
    install(omarchy, everydayCli)
    install(omarchy, voxtype, code, sublimeText, obsidian, spotify, vlc, onePassword, onePasswordCli)
    install(ttfFiracodeNerd, wtype, zenity) // omarchy, their only variant
    install(omarchyAur, antigravity, slack, teamsForLinux, anydesk)
    install(voxtypeTui, brave) // omarchy-aur, their only variant

    install(
        setupBrew.variant(name = "linux"),
        jetbrainsToolbox.variant(name = "linux"),
        tpack.variant(name = "linux"),
    )
    install(ngrok)
    install(brew, just, vim, scrcpy)
    install(workmux, awscli, trashCli, yq) // brew, their only variant
    install(brewCask, googleCloudCli)

    // claude comes from mise here (conf.d/omarchy.toml).
    run(Dotfiles.all)
    run(setupGit, skillsRepo, defaultShell, nvimPlugins, unlinkBrewGlib, keychronLauncherAccess)
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

    // The shell and its bar
    run(OmarchyShell.bar, "top", "24", "tornikegomareli.spaces")
    run(
        OmarchyShell.plugins,
        "https://github.com/evindor/keystroke.git",
        "https://github.com/jankeesvw/omarchy-notification-center.git",
        "https://github.com/tornikegomareli/omarchy-spaces.git",
        "https://github.com/binoymanoj/pomodoro-omarchy.git",
        "https://github.com/Zeus-Deus/voxtype-omarchy-plugin.git",
        "https://github.com/sumdahl/omarchy-plugin-media.git",
    )
    run(
        OmarchyShell.barIcons,
        "josemiguelo.menu-button", "josemiguelo.workspace-layout", "josemiguelo.theme-mode",
        "omarchy.monitor", "omarchy.bluetooth", "omarchy.network", "omarchy.audio",
        "omarchy.power", "omarchy.agents", "omarchy.system-update", "omarchy.indicators",
        "omarchy.weather", "omarchy.tray",
        "jankeesvw.notification-center", "io.github.zeus-deus.voxtype", "io.github.sumdahl.media",
        "pomodoro-omarchy", "omarchy.clock", "tornikegomareli.spaces",
    )
    run(
        OmarchyShell.barWidgets,
        widget("josemiguelo.workspace-layout").left.before("tornikegomareli.spaces"),
        widget("josemiguelo.menu-button").left.before("josemiguelo.workspace-layout"),
        widget("io.github.sumdahl.media").right.after("omarchy.tray"),
        widget("omarchy.power").right.after("omarchy.monitor"),
        widget("josemiguelo.theme-mode").right.before("omarchy.tray"),
    )
    run(OmarchyShell.menuButton, OmarchyShell.keystrokeWindows, OmarchyShell.pomodoro)

    // Apps the Omarchy way
    run(Omarchy.onePassword, Omarchy.vscode, Omarchy.brave)
    run(Omarchy.defaultBrowser, "brave")
    run(Omarchy.agentLaunchersPrune, "claude", "codex", "gh", "gemini")

    // Web apps: Google's in HEY's place
    run(Webapps.remove, "Basecamp", "HEY")
    run(Webapps.gmail, Webapps.googleCalendar)

    run(Overrides.commands, Overrides.keyboardBacklightGuard)
    run(Dictation.setup, Dictation.gpu)
}
