# Apps set up the Omarchy way. The apps themselves are programs; the
# scripts source .loadout/lib/.

# Omarchy's own setup of apps the machine installs, the omarchy-<app>
# scripts: `run = [script.omarchy-brave]`; the app is `program.brave`.

# Omarchy's installer (Chromium extension entry), started unscaled at login,
# Ctrl+Shift+Space for Quick Access.
script "omarchy-1password" {
  description = "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access"
  managed_by  = ".loadout/omarchy-1password.sh"
  needs_sudo  = true
  run_after   = [program["1password"], program["1password-cli"]]
}

script "omarchy-brave" {
  description = "Brave, set up by Omarchy's browser installer"
  managed_by  = ".loadout/omarchy-brave.sh"
  needs_sudo  = true
  run_after   = [program.brave]
}

# The default browser, named by the machine:
# `args(script.omarchy-default-browser, "brave")`.
script "omarchy-default-browser" {
  description = "Omarchy's default browser"
  file        = ".loadout/omarchy-default-browser-arch.sh"
  check       = "test \"$(omarchy default browser)\" = \"$1\""
  run_after   = [program.brave, script.omarchy-brave]
}

# Omarchy's installer (keyring, no self-update, its theme); overwrites
# settings.json and opens VS Code once.
script "omarchy-vscode" {
  description = "VS Code, set up by Omarchy's installer"
  managed_by  = ".loadout/omarchy-vscode.sh"
  run_after   = [program.code]
}

# docker group membership: root-equivalent, so opted into per machine.
script "omarchy-sudoless-docker" {
  description = "sudoless Docker (user in the docker group)"
  managed_by  = ".loadout/omarchy-sudoless-docker.sh"
  needs_sudo  = true
  run_after   = [program.lazydocker]
}

# Omarchy's agent launchers (~/.local/bin) and seeded configs (~/.config),
# pruned to the agents the machine names.
script "omarchy-agents-prune" {
  description = "only the Omarchy agent launchers and configs in use"
  managed_by  = ".loadout/omarchy-agents-prune.sh"
}
