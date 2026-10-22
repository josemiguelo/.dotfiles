// nvim: the lazy.nvim plugins lazy-lock.json locks. Neovim itself (nightly)
// comes from mise's config.toml.
package loadouts

import loadout.dsl.*

// Presence: clones at the commits lazy-lock.json locks. Freshness: what Lazy
// itself calls outdated (it honours each plugin's version/tag/commit/pin),
// one row per plugin, updated through Lazy so the lockfile keeps one writer;
// bring it back with `chezmoi re-add`.
val nvimPlugins = script(
    name = "nvim-plugins",
    description = "lazy.nvim plugins at the commits lazy-lock.json locks",
) {
    managedBy(".loadout/plugins.sh")
    runAfter(Mise.tools)
    updatesManagedBy(".loadout/outdated-plugins.sh")
}

// kotlin.nvim's server, from its GitHub release while Mason's download link
// is dead; kotlin.lua points the plugin at it. Its builds expire weeks after
// release, so the update check keeps it current.
val kotlinLsp = program(
    name = "kotlin-lsp",
    description = "Kotlin language server for Neovim (kotlin.nvim)",
) {
    custom {
        installedBy(".loadout/install-kotlin-lsp.sh")
    }
    version(command = runScript(".loadout/outdated-kotlin-lsp.sh version"))
    updatesManagedBy(".loadout/outdated-kotlin-lsp.sh")
}
