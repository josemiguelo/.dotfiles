# Obsidian Sync without the app: Obsidian Headless (`ob`, a mise tool), the
# native binding it can't always fetch for itself, and the vault it syncs.

# omalauncher: the native binding obsidian-headless's own install can't fetch
# there.
script "obsidian-headless-sqlite" {
  description = "better-sqlite3's prebuilt binding for mise's obsidian-headless"
  managed_by  = ".loadout/headless-sqlite.sh"
  run_after   = [script.mise-tools]
}

# A vault synced into a folder, named by the machine:
# `args(script.obsidian-sync, "<vault>", "<path>", "<mode>")`.
script "obsidian-sync" {
  description = "an Obsidian Sync vault in a local folder, through ob"
  managed_by  = ".loadout/sync.sh"
  run_after   = [script.mise-tools, script.obsidian-headless-sqlite]
}

program "obsidian" {
  description = "Obsidian notes"
  via "flatpak" { pkg = "md.obsidian.Obsidian" }
  install_via = [omarchy]  # Omarchy preinstalls Arch's package and its launch flags
}
