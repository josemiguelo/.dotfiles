# mise: the tool-version manager, the tools config.toml pins, the default
# packages inside them, and what depends on those tools.

program "mise" {
  description = "mise tool-version manager"

  # On Omarchy, Omarchy's own mise-bin, ahead of Arch's extra/mise.
  via "omarchy" { pkg = "mise-bin" }
  via "brew" {}

  # omalauncher's Arch: mise's own installer, into ~/.local/bin, where the
  # launcher's install put it; `mise self-update` moves it.
  # Its oracle is this variant's alone: a program-level one would replace
  # the installers' (Omarchy's pacman, brew) for every machine.
  custom "mise-run" {
    command  = "curl -fsSL https://mise.run | sh"
    version  = "$HOME/.local/bin/mise --version"
    outdated = run_script(".loadout/outdated-mise.sh")
  }
}

# What mise installs inside itself, and what builds on it: `run = [script.mise-tools]`.

# Exactly the versions config.toml pins; and whether those pins are behind
# upstream.
# Bun left mise's tools: the system's (program.bun) is the one Bun, the one
# loadout's scripts run with. mise keeps an uninstalled tool's versions.
# From $HOME, where mise reads the global config only.
script "mise-drop-bun" {
  description  = "no Bun from mise (the system's is the one Bun)"
  run          = "cd \"$HOME\" && mise uninstall --all bun"
  check        = "cd \"$HOME\" && ! mise ls --installed bun 2>/dev/null | grep -q ."
  run_after    = [script.mise-tools]
  transitional = true
}

# OpenSSL 1.1 beside the system's: Python 2.7's ssl module builds against
# 1.x only, and Arch dropped 1.1 from its repos. tools.sh builds the 2.x
# pythons config.toml pins against it.
program "openssl-1.1" {
  description = "OpenSSL 1.1, for mise's Python 2.7 builds"
  via "omarchy-aur" {}
}

script "mise-tools" {
  description        = "mise tools at the versions ~/.config/mise/config.toml pins"
  managed_by         = ".loadout/tools.sh"
  run_after          = [program.mise, program["openssl-1.1"]]
  updates_managed_by = ".loadout/outdated-tools.sh"
}

# mise seeds default packages only into versions it installs later; this
# backfills every one.
script "mise-default-packages" {
  description = "default npm/gem packages in every mise node/ruby version"
  managed_by  = ".loadout/default-packages.sh"
  run_after   = [script.mise-tools]
}

# mise's JDKs registered in /Library/Java/JavaVirtualMachines, as
# asdf-java's macOS integration did. The macos profile runs it.
script "java-macos-integration" {
  description = "mise's JDKs registered with macOS (java_home)"
  managed_by  = ".loadout/java-macos.sh"
  needs_sudo  = true
  run_after   = [script.mise-tools]
}

# The coding agent Omarchy's keybinding and menu launch (it comes from mise),
# named by the machine: `args(script.omarchy-default-agent, "claude")`.
script "omarchy-default-agent" {
  description = "Omarchy's default coding agent"
  file        = ".loadout/default-agent.sh"
  check       = "test \"$(omarchy default agent)\" = \"$1\""
  run_after   = [script.mise-tools]
}
