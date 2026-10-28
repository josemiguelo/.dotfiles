// dnf: its config before any dnf install, and the plugins its COPR
// mechanism needs. Every dnf installer `requires` setup-dnf, so it runs
// before any dnf install.
package loadouts

import loadout.dsl.*

val setupDnf = program(
    name = "setup-dnf",
    description = "dnf.conf performance and behavior tweaks",
) {
    installVia(
        dnf {
            managedBy(".loadout/setup-dnf.sh")
            needsSudo()
        },
    )
}

/** Provides the copr command the dnf-copr mechanism runs. */
val dnfPluginsCore = program(
    name = "dnf-plugins-core",
    description = "dnf plugins (provides the copr command)",
) {
    installVia(
        dnf,
    )
}

val dnfSetup = run {
    // Every dnf install waits for dnf.conf; setup-dnf, itself a dnf
    // variant, is exempt from its own rule.
    dnf.requires(setupDnf)
    dnfRepo.requires(setupDnf)
    dnfCopr.requires(setupDnf, dnfPluginsCore) // kitty no longer says it
}
