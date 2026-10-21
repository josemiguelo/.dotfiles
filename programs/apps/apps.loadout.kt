// Desktop apps. Vendor .repo files are in repos/, Fedora install scripts in
// fedora/.
package repo

import loadout.dsl.*

// ─── Browsers ───

val firefox = program(
    name = "firefox",
    description = "Firefox browser",
) {
    installVia(
        dnf {
            installedBy("fedora/install-firefox.sh")
            needsSudo()
        },
    )
}

/** The rpm firefox wins; the flatpak goes. */
val removeFirefoxFlatpak = script(
    name = "remove-firefox-flatpak",
    description = "remove the firefox flatpak",
) {
    run("flatpak --user uninstall --delete-data -y org.mozilla.firefox")
    check("! flatpak --user info org.mozilla.firefox >/dev/null 2>&1")
}

val googleChromeStable = program(
    name = "google-chrome-stable",
    description = "Google Chrome browser",
) {
    installVia(
        dnf {
            installedBy("fedora/install-chrome.sh")
            needsSudo()
        },
    )
}

// The AUR's brave-bin (Brave's own build, repackaged), what Omarchy's
// `omarchy install browser brave` adds. The omarchy-brave script runs that
// installer for Omarchy's policy, flags and theme.
val brave = program(
    name = "brave",
    description = "Brave browser",
) {
    installVia(
        omarchyAur(pkg = "brave-bin"),
    )
}

// ─── Editors ───

val code = program(
    name = "code",
    description = "Visual Studio Code",
) {
    installVia(
        dnfRepo(repofile = file("repos/vscode.repo")),
        // Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
        omarchy(pkg = "visual-studio-code-bin"),
    )
}

val antigravity = program(
    name = "antigravity",
    description = "Antigravity IDE",
) {
    installVia(
        dnfRepo(repofile = file("repos/antigravity.repo")),
        // Google's IDE tarball, repackaged; not the AUR's `antigravity` (2.0, a
        // different product).
        omarchyAur(pkg = "antigravity-ide"),
    )
}

// Versions are build numbers (4192). The vendor publishes a per-arch .repo;
// the shell running the install expands $(uname -m).
val sublimeText = program(
    name = "sublime-text",
    description = "Sublime Text editor",
) {
    installVia(
        dnfRepo(repofile = "https://download.sublimetext.com/rpm/stable/\$(uname -m)/sublime-text.repo") {
            regex = """([0-9]+)"""
        },
        // pacman's version is "4.<build>", which the dotted regex reads whole.
        omarchy(pkg = "sublime-text-4"),
    )
}

// ─── Communication ───

val slack = program(
    name = "slack",
    description = "Slack desktop app",
) {
    installVia(
        dnfRepo(repofile = file("repos/slack.repo")),
        omarchyAur(pkg = "slack-desktop"), // Slack's own build, repackaged
    )
}

val teamsForLinux = program(
    name = "teams-for-linux",
    description = "Microsoft Teams client",
) {
    installVia(
        dnfRepo(repofile = "https://repo.teamsforlinux.de/rpm/teams-for-linux.repo"),
        omarchyAur(pkg = "teams-for-linux-bin"), // the source package rebuilds Electron
    )
}

val anydesk = program(
    name = "anydesk",
    description = "AnyDesk remote desktop",
) {
    installVia(
        dnf {
            installedBy("fedora/install-anydesk.sh")
            needsSudo()
        },
        // AnyDesk's own build; its unattended-access service is left disabled.
        omarchyAur(pkg = "anydesk-bin"),
    )
}

// ─── Passwords ───

val onePassword = program(
    name = "1password",
    description = "1Password desktop app",
) {
    installVia(
        dnfRepo(repofile = file("repos/1password.repo")),
        // Omarchy's [omarchy] repo; omarchy-1password finishes the setup.
        omarchy,
    )
}

val onePasswordCli = program(
    name = "1password-cli",
    description = "1Password CLI (op)",
) {
    installVia(
        omarchy,
        brewCask,
    )
}

// ─── Media and notes ───

val spotify = program(
    name = "spotify",
    description = "Spotify music streaming",
) {
    installVia(
        omarchy, // Omarchy's own repo carries it
        brewCask {
            spare(reason = "for macOS; no Mac installs it yet")
        },
    )
}

val vlc = program(
    name = "vlc",
    description = "VLC media player",
) {
    installVia(
        dnf,
        omarchy,
    )
}

val obs = program(
    name = "obs",
    description = "OBS Studio -- screen recording/streaming",
) {
    installVia(
        brewCask,
    )
}

/** Flathub as a user-level remote, so flatpaks can depend on it. */
val flathubRemote = program(
    name = "flathub-remote",
    description = "flathub flatpak remote (user)",
) {
    // A remote, not an app: the probe comes from flatpak, the rest is its own.
    installVia(
        flatpak {
            command = "flatpak --user remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo"
            present("flatpak --user remotes --columns=name | grep -x flathub")
        },
    )
}

val flatpakSetup = flatpak.requires(flathubRemote) // every flatpak needs the remote first

val obsidian = program(
    name = "obsidian",
    description = "Obsidian notes",
) {
    installVia(
        flatpak(pkg = "md.obsidian.Obsidian"),
        omarchy, // Omarchy preinstalls Arch's package and its launch flags
    )
}

// ─── macOS menu bar ───

val jordanbairdIce = program(
    name = "jordanbaird-ice",
    description = "Ice -- menu bar icon organizer",
) {
    installVia(
        brewCask,
    )
}

val lunar = program(
    name = "lunar",
    description = "Lunar -- external display brightness/contrast control",
) {
    installVia(
        brewCask,
    )
}

val meetingbar = program(
    name = "meetingbar",
    description = "MeetingBar -- calendar meetings in the menu bar",
) {
    installVia(
        brewCask,
    )
}

// ─── Android ───

val scrcpy = program(
    name = "scrcpy",
    description = "scrcpy Android screen mirroring",
) {
    installVia(
        brew,
        dnfCopr(copr = "zeno/scrcpy"),
    )
}

// ─── Dictation ───

// Push-to-talk speech-to-text. macOS: a cask from its own tap. Omarchy:
// voxtype-bin from [omarchy], which maintenance/omarchy/dictation sets up around it.
val voxtype = program(
    name = "voxtype",
    description = "Voxtype push-to-talk speech-to-text",
) {
    installVia(
        tapCask(tap = "peteonrails/voxtype"),
        omarchy(pkg = "voxtype-bin"),
    )
}

// macOS: the first-time setup, as a step that stays pending until
// Voxtype.app exists.
// It runs `voxtype configure` (interactive) and the app bundle, then prints
// the permissions left for System Settings.
val voxtypeSetup = script(
    name = "voxtype-setup",
    description = "Voxtype configured, Voxtype.app created (macOS)",
) {
    managedBy("voxtype-setup.sh")
    needsSudo()
    runAfter(voxtype)
}
