package repo

import loadout.dsl.*

/** Every macOS machine. macOS ships zsh as the login shell, so zsh is neither installed nor switched to. */
val macos = profile(name = "macos") {
    install(setupBrew.variant(name = "macos"))
    install(brew, everydayCli)
    install(brew, scrcpy, chezmoi, mise, tmux)
    install(
        workmux, terraform, awscli, trashCli, yq, azureCli, coreutils, gawk,
        gh, gnuSed, jiraCli, jq, qemu, tree, unixodbc, wget, tryCli,
    ) // brew, their only variant
    install(brewCask, kitty, onePasswordCli)
    install(raycast, codex, jordanbairdIce, lunar, meetingbar, obs) // casks, their only variant
    install(brewTapCask, tpack, voxtype)
    install(ngrok, claude)

    run(Dotfiles.all)
    run(setupGit, skillsRepo, nvimPlugins, downloadFonts)
    run(shellScripts)
    run(Mise.tools, Mise.defaultPackages, Mise.javaMacosIntegration)
    run(tmuxPlugins)
    run(voxtypeSetup)
}
