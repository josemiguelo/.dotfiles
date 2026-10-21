package repo

import loadout.dsl.*

/** Every macOS machine. macOS ships zsh as the login shell, so zsh is neither installed nor switched to. */
val macos = profile(name = "macos") {
    install(setupBrew.variant(name = "macos"))
    via(brew) {
        install(everydayCli)
        install(scrcpy, chezmoi, mise, tmux)
        install(
            awscli, trashCli, yq, azureCli, coreutils, gawk,
            gh, gnuSed, jiraCli, jq, qemu, tree, unixodbc, wget, tryCli,
        )
    }
    via(brewTap) {
        install(workmux, terraform)
    }
    via(brewCask) {
        install(kitty, onePasswordCli)
        install(raycast, codex, jordanbairdIce, lunar, meetingbar, obs)
    }
    via(brewTapCask) {
        install(tpack, voxtype)
    }
    install(ngrok, claude, kotlinLsp)

    run(Dotfiles.all)
    run(setupGit, skillsRepo, workmuxSetup, nvimPlugins, downloadFonts)
    run(shellScripts)
    run(Mise.tools, Mise.defaultPackages, Mise.javaMacosIntegration)
    run(tmuxPlugins)
    run(voxtypeSetup)
}
