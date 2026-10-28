// Homebrew: brew itself, its mechanisms, and third-party taps. brew.sh,
// setup-brew.sh and brew-taps.sh are in .loadout/.
package loadouts

import loadout.dsl.*

// Homebrew must exist and be writable by the login user before anything
// installs with brew. Homebrew is single-owner: a prefix installed by another
// account fails every `brew install`, so the Linux script reclaims it. PATH
// is not touched here: brew reaches interactive shells via the zsh plugin.
val setupBrew = program(
    name = "setup-brew",
    description = "Homebrew installed and owned by the login user",
) {
    // Linux: /home/linuxbrew, reclaimed for the login user, after Homebrew's
    // own build prerequisites.
    custom(name = "linux") {
        managedBy(".loadout/setup-brew.sh")
        needsSudo()
        dependsOn(curl, git, gcc, procpsNg)
    }

    // macOS: the official installer into /opt/homebrew. It asks for sudo
    // itself; Xcode's command line tools come with it.
    custom(name = "macos") {
        command = "NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        needsSudo()
        version(command = runScript(".loadout/brew.sh --version"), regex = """Homebrew ([0-9][0-9.]*)""")
    }
}

// The brew mechanisms replace the built-ins of the same name so brew is
// reached by absolute path (brew.sh): on a fresh machine programs converge
// before any shell has run `brew shellenv`. The rest matches the built-in.
private const val OUTDATED_AWK = """awk '{n=${'$'}1; sub(/.*[/]/, "", n); v=${'$'}NF; gsub(/[()]/, "", v); print n, v}'"""

val brew = installer(name = "brew") {
    install = runScript(".loadout/brew.sh install {pkg}")
    upgrade = runScript(".loadout/brew.sh upgrade")
    check = runScript(".loadout/brew.sh list --versions {pkg}")
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 sh .loadout/brew.sh outdated --verbose | $OUTDATED_AWK"
}

val brewCask = installer(name = "brew-cask") {
    install = runScript(".loadout/brew.sh install --cask {pkg}")
    upgrade = runScript(".loadout/brew.sh upgrade --cask")
    check = runScript(".loadout/brew.sh list --cask --versions {pkg}")
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 sh .loadout/brew.sh outdated --cask --verbose | $OUTDATED_AWK"
}

// A formula or cask from a third-party tap: tapped and trusted (trust is
// per user), then installed by its full path, `<tap>/<pkg>`. pkg stays the
// bare name, which is what `brew list` and the outdated oracle report.
val brewTap = installer(name = "brew-tap") {
    params("tap")
    install = runScript(".loadout/brew-taps.sh install {tap} {tap}/{pkg}")
    upgrade = runScript(".loadout/brew.sh upgrade")
    check = runScript(".loadout/brew.sh list --versions {pkg}")
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 sh .loadout/brew.sh outdated --verbose | $OUTDATED_AWK"
}

val brewTapCask = installer(name = "brew-tap-cask") {
    params("tap")
    install = runScript(".loadout/brew-taps.sh install {tap} {tap}/{pkg} --cask")
    upgrade = runScript(".loadout/brew.sh upgrade --cask")
    check = runScript(".loadout/brew.sh list --cask --versions {pkg}")
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 sh .loadout/brew.sh outdated --cask --verbose | $OUTDATED_AWK"
}

/** A formula from [tap]: `installVia(tap(tap = "hashicorp/tap"))`. */
fun tap(tap: String, pkg: String? = null, block: VariantScope.() -> Unit = {}): InstallMethod =
    brewTap(pkg) { param("tap", tap); block() }

/** A cask from [tap]: `installVia(tapCask(tap = "tmuxpack/tpack"))`. */
fun tapCask(tap: String, pkg: String? = null, block: VariantScope.() -> Unit = {}): InstallMethod =
    brewTapCask(pkg) { param("tap", tap); block() }

val brewSetup = run {
    // Homebrew must exist and be writable by the login user first.
    brew.requires(setupBrew)
    brewCask.requires(setupBrew)
    brewTap.requires(setupBrew)
    brewTapCask.requires(setupBrew)
}
