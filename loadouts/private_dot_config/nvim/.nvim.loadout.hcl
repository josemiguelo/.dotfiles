# nvim: the lazy.nvim plugins lazy-lock.json locks. Neovim itself (nightly)
# comes from mise's config.toml.

# Presence: clones at the commits lazy-lock.json locks. Freshness: what Lazy
# itself calls outdated (it honours each plugin's version/tag/commit/pin),
# one row per plugin, updated through Lazy so the lockfile keeps one writer;
# bring it back with `chezmoi re-add`.
script "nvim-plugins" {
  description        = "lazy.nvim plugins at the commits lazy-lock.json locks"
  managed_by         = ".loadout/plugins.ts"
  run_after          = [script.mise-tools]
  updates_managed_by = ".loadout/outdated-plugins.ts"
}

# kotlin.nvim's server, installed by Mason (kotlin.lua asks for it too). Its
# builds expire weeks after release and Mason never updates by itself, so
# Mason's newer build shows up as outdated here. A script, not a program:
# Mason comes with the lazy plugins, after every program is installed.
script "mason-kotlin-lsp" {
  description        = "kotlin-lsp for kotlin.nvim, from Mason"
  later              = "a large download only Kotlin editing needs"
  managed_by         = ".loadout/mason-kotlin-lsp.ts"
  run_after          = [script.nvim-plugins]
  updates_managed_by = ".loadout/outdated-kotlin-lsp.ts"
}

# The copy an earlier version downloaded from kotlin-lsp's GitHub releases
# while Mason's download link was dead (mason-registry#17523).
script "remove-kotlin-lsp-download" {
  description  = "no kotlin-lsp download outside Mason"
  later        = "cleans up after mason-kotlin-lsp, which is later"
  run          = "rm -rf \"$HOME/.local/share/kotlin-lsp\""
  check        = "test ! -e \"$HOME/.local/share/kotlin-lsp\""
  run_after    = [script.mason-kotlin-lsp]
  transitional = true
}
