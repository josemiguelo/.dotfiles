# nvim: the lazy.nvim plugins lazy-lock.json locks. Neovim itself (nightly)
# comes from mise's config.toml.

# Presence: clones at the commits lazy-lock.json locks. Freshness: what Lazy
# itself calls outdated (it honours each plugin's version/tag/commit/pin),
# one row per plugin, updated through Lazy so the lockfile keeps one writer;
# bring it back with `chezmoi re-add`.
script "nvim-plugins" {
  description        = "lazy.nvim plugins at the commits lazy-lock.json locks"
  managed_by         = ".loadout/plugins.sh"
  run_after          = [script.mise-tools]
  updates_managed_by = ".loadout/outdated-plugins.sh"
}

# kotlin.nvim's server, from its GitHub release while Mason's download link
# is dead; kotlin.lua points the plugin at it. Its builds expire weeks after
# release, so the update check keeps it current.
program "kotlin-lsp" {
  description = "Kotlin language server for Neovim (kotlin.nvim)"

  custom {
    installed_by = ".loadout/install-kotlin-lsp.sh"
  }

  version            = run_script(".loadout/outdated-kotlin-lsp.sh version")
  updates_managed_by = ".loadout/outdated-kotlin-lsp.sh"
}
