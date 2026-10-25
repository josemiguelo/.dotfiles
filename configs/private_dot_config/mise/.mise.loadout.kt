// mise: the tool-version manager, the tools config.toml pins, the default
// packages inside them, and what depends on those tools.
package loadouts

import loadout.dsl.*

val mise = program(
    name = "mise",
    description = "mise tool-version manager",
) {
    // On Omarchy, Omarchy's own mise-bin, ahead of Arch's extra/mise.
    installVia(
        omarchy(pkg = "mise-bin"),
        brew,
    )

    // omalauncher's Arch: mise's own installer, into ~/.local/bin, where the
    // launcher's install put it; `mise self-update` moves it.
    custom(name = "mise-run") {
        command = "curl -fsSL https://mise.run | sh"
        version(command = "$HOME/.local/bin/mise --version")
    }
}

/** What mise installs inside itself, and what builds on it: `run(Mise.tools)`. */
object Mise {
    // Exactly the versions config.toml pins; and whether those pins are behind
    // upstream.
    val tools = script(
        name = "mise-tools",
        description = "mise tools at the versions ~/.config/mise/config.toml pins",
    ) {
        managedBy(".loadout/tools.sh")
        runAfter(mise)
        updatesManagedBy(".loadout/outdated-tools.sh")
    }

    /** mise seeds default packages only into versions it installs later; this backfills every one. */
    val defaultPackages = script(
        name = "mise-default-packages",
        description = "default npm/gem packages in every mise node/ruby version",
    ) {
        managedBy(".loadout/default-packages.sh")
        runAfter(tools)
    }

    // mise's JDKs registered in /Library/Java/JavaVirtualMachines, as
    // asdf-java's macOS integration did. The macos profile runs it.
    val javaMacosIntegration = script(
        name = "java-macos-integration",
        description = "mise's JDKs registered with macOS (java_home)",
    ) {
        managedBy(".loadout/java-macos.sh")
        needsSudo()
        runAfter(tools)
    }

    /** The coding agent Omarchy's keybinding and menu launch (it comes from mise), named by the machine: `run(Mise.omarchyDefaultAgent, "claude")`. */
    val omarchyDefaultAgent = script(
        name = "omarchy-default-agent",
        description = "Omarchy's default coding agent",
    ) {
        file(".loadout/default-agent.sh")
        check("test \"\$(omarchy default agent)\" = \"\$1\"")
        runAfter(tools)
    }
}
