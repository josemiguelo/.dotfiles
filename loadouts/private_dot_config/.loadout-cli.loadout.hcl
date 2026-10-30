# Its release, into ~/.local; `loadout sync` and `self-upgrade` keep it
# current.
program "loadout" {
  description = "loadout, which reads this repo"

  custom {
    command = "curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh"
  }

  path    = ["$HOME/.local/bin"]
  version = "loadout --version"
}
