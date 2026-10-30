# Surfingkeys: Brave's vim-like keys, its settings in ~/.config/surfingkeys/surfingkeys.js, and the extension its split-view keys drive.

# Surfingkeys installed in Brave and allowed to read file URLs, so its
# "Load settings from" can point at the deployed surfingkeys.js. Brave keeps
# both in its own profile, so `install` only says what to do there.
script "surfingkeys" {
  description = "Surfingkeys in Brave, reading ~/.config/surfingkeys/surfingkeys.js"
  managed_by  = ".loadout/surfingkeys.sh"
  run_after   = [program.brave]
}

# The "Split view keys" extension beside surfingkeys.js, which Surfingkeys'
# gs and gS ask to open a link in Brave's split view and to close it. Its
# path joins Omarchy's --load-extension line in brave-flags.conf.
script "surfingkeys-split-view" {
  description = "Brave loads the Split view keys extension behind Surfingkeys' gs"
  managed_by  = ".loadout/split-view.sh"
  run_after   = [script.omarchy-brave]
}
