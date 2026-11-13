# jm's machines: programs, scripts, machines and dotfiles in one repo.
# chezmoi reads loadouts/ (.chezmoiroot); its templates read each machine's
# merged data from loadout.lock.json.

# The manifest files, in compile order after this one (loadout's glob rules:
# dot-files match only when the glob spells the dot, and ** never enters a
# dot folder, hence the second loadouts glob for the config-less tools'
# ones, and the third for what lands outside $HOME, in .etc/<concern>/).
repo {
  name             = "jm's machines"
  state            = "machines/state"
  configs          = "loadouts"
  min_tool_version = "4.5.0"
  # The bun loadout's scripts run with: loadout downloads it and puts it
  # first on PATH for every command it runs, so TypeScript works from a new
  # machine's first step. mise's bun (mise/config.toml) is the shells'; the
  # pre-commit hook keeps the two at one version.
  bun = "1.4.3"
  sources = [
    "loadouts/**/.*.loadout.hcl",
    "loadouts/**/.*/.*.loadout.hcl",
    "loadouts/.etc/*/.*.loadout.hcl",
    "machines/**/*.loadout.hcl",
  ]
}

# Every per-machine setting, with its default. Dotfile templates branch on
# these, not on hostnames.
data {
  # An Omarchy machine (Linuxbrew reaches the shell from the zsh config).
  omarchy = flag(false)

  # The work machine: work-only tools in, personal ones (e.g. Copilot) out;
  # the rest comes from its private child repo.
  work = flag(false)

  kitty {
    # background_opacity; Omarchy's scratchpad repaints its own windows on top.
    opacity = number(0.85)
  }
}
