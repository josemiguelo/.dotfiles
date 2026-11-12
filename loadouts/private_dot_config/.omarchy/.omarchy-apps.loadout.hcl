# Apps set up the Omarchy way. The apps themselves are programs; the
# scripts import .loadout/lib/.

# Omarchy's own setup of apps the machine installs, the omarchy-<app>
# scripts: `run = [script.omarchy-brave]`; the app is `program.brave`.

# Omarchy's installer (Chromium extension entry), started unscaled at login,
# Ctrl+Shift+Space for Quick Access.
script "omarchy-1password" {
  description = "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access"
  managed_by  = ".loadout/omarchy-1password.ts"
  needs_sudo  = true
  run_after   = [program["1password"], program["1password-cli"]]
}

script "omarchy-brave" {
  description = "Brave, set up by Omarchy's browser installer"
  managed_by  = ".loadout/omarchy-brave.ts"
  needs_sudo  = true
  run_after   = [program.brave]
}

# What Surfingkeys left in Brave's flags: the split view extension's entry on
# the --load-extension line (its files go through .chezmoiremove).
script "remove-surfingkeys" {
  description  = "no Surfingkeys split view extension on Brave's --load-extension line"
  managed_by   = ".loadout/remove-surfingkeys.ts"
  run_after    = [script.omarchy-brave]
  transitional = true
}

# The default browser, named by the machine:
# `args(script.omarchy-default-browser, "brave")`.
script "omarchy-default-browser" {
  description = "Omarchy's default browser"
  file        = ".loadout/omarchy-default-browser-arch.ts"
  check       = "test \"$(omarchy default browser)\" = \"$1\""
  run_after   = [program.brave, script.omarchy-brave]
}

# Superwhisper as the dictation backend Omarchy's keys (Alt+Space, Right Alt)
# run, set by Omarchy's own installer, unattended (--background): it installs
# superwhisper-bin when missing (Omarchy 4.5 ships it, but a machine upgraded
# from before may not have it), runs its per-user setup and makes it the
# backend. What a fresh 4.5 install's first run does.
script "omarchy-default-dictation" {
  description = "Superwhisper as Omarchy's dictation backend"
  run         = "omarchy-install-dictation-superwhisper --background"
  check       = "test \"$(omarchy default dictation 2>/dev/null)\" = superwhisper"
  needs_sudo  = true
}

# What this repo added around Voxtype, Omarchy's dictation backend here before
# Superwhisper: its bar plugin and settings TUI. Voxtype itself stays as
# Omarchy's installer left it.
script "omarchy-remove-voxtype-extras" {
  description  = "no Voxtype bar plugin or settings TUI (stock Voxtype stays)"
  run          = "omarchy plugin remove io.github.zeus-deus.voxtype --yes; omarchy-pkg-drop voxtype-tui"
  check        = "! pacman -Q voxtype-tui >/dev/null 2>&1 && test ! -e \"$HOME/.config/omarchy/plugins/io.github.zeus-deus.voxtype\""
  needs_sudo   = true
  run_after    = [script.omarchy-default-dictation]
  transitional = true
}

# Omarchy's installer (keyring, no self-update, its theme); overwrites
# settings.json and opens VS Code once.
script "omarchy-vscode" {
  description = "VS Code, set up by Omarchy's installer"
  managed_by  = ".loadout/omarchy-vscode.ts"
  run_after   = [program.code]
}

# docker group membership: root-equivalent, so opted into per machine.
script "omarchy-sudoless-docker" {
  description = "sudoless Docker (user in the docker group)"
  managed_by  = ".loadout/omarchy-sudoless-docker.ts"
  needs_sudo  = true
  run_after   = [program.lazydocker]
}

# Omarchy's agent launchers (~/.local/bin) and seeded configs (~/.config),
# pruned to the agents the machine names.
script "omarchy-agents-prune" {
  description = "only the Omarchy agent launchers and configs in use"
  managed_by  = ".loadout/omarchy-agents-prune.ts"
}
