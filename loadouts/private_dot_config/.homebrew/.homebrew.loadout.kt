// Homebrew: brew itself, and third-party taps. brew.sh, setup-brew.sh and
// brew-taps.sh are in .loadout/. brew and brew-cask are loadout's own.
package loadouts

import loadout.dsl.*

// Homebrew must exist and be writable by the login user before anything
// installs with brew. Homebrew is single-owner: a prefix installed by another
// account fails every `brew install`, so the Linux script reclaims it. PATH
// is not touched here: brew reaches interactive shells via the zsh plugin,
// and loadout's brew commands via `provides(at = …)`, which restates
// brew-prefix.sh's prefix (loadout can't source it): change both together.
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
        provides("brew", at = "/home/linuxbrew/.linuxbrew/bin")
    }

    // macOS: the official installer into /opt/homebrew. It asks for sudo
    // itself; Xcode's command line tools come with it.
    custom(name = "macos") {
        command = "NONINTERACTIVE=1 /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
        needsSudo()
        version(command = runScript(".loadout/brew.sh --version"), regex = """Homebrew ([0-9][0-9.]*)""")
        provides("brew", at = "/opt/homebrew/bin")
    }
}

private const val OUTDATED_AWK = """awk '{n=${'$'}1; sub(/.*[/]/, "", n); v=${'$'}NF; gsub(/[()]/, "", v); print n, v}'"""

// A formula or cask from a third-party tap: tapped and trusted (trust is
// per user), then installed by its full path, `<tap>/<pkg>`. pkg stays the
// bare name, which is what `brew list` and the outdated oracle report. The
// rest is the built-ins', brew found the same way (setup-brew's `provides`),
// so `loadout upgrade` runs one `brew upgrade` for brew and brew-tap.
val brewTap = installer(name = "brew-tap") {
    params("tap")
    probe = "brew"
    install = runScript(".loadout/brew-taps.sh install {tap} {tap}/{pkg}")
    upgrade = "brew upgrade"
    check = "brew list --versions {pkg}"
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --verbose | $OUTDATED_AWK"
}

val brewTapCask = installer(name = "brew-tap-cask") {
    params("tap")
    probe = "brew"
    install = runScript(".loadout/brew-taps.sh install {tap} {tap}/{pkg} --cask")
    upgrade = "brew upgrade --cask"
    check = "brew list --cask --versions {pkg}"
    outdatedAll = "HOMEBREW_NO_AUTO_UPDATE=1 brew outdated --cask --verbose | $OUTDATED_AWK"
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
