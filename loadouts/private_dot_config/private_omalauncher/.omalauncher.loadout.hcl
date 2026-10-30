# omalauncher: the launcher's files on this phone, kept in the repo as they
# are on the phone, and the packages they declare installed.

# Phone -> repo: new launcher files added, changed ones re-added, deleted ones
# forgotten (widgets' Claude hook runs it on every save).
script "omalauncher-tracked" {
  description = "the launcher's files on this phone, as they are, in the repo"
  managed_by  = ".loadout/tracked.sh"
  run_after   = [program.chezmoi]
}

# Home read again when the launcher left out widgets it read layout.toml too
# early to see (a new install's apply).
script "omalauncher-layout" {
  description = "home as layout.toml says, once the widgets it names are there"
  managed_by  = ".loadout/layout.sh"
  run_after   = [program.chezmoi]
}

# What the widgets' `requires { pacman: [...] }` declare: the files are the
# record, nothing else lists them.
script "omalauncher-requires" {
  description = "every package the launcher's widgets declare"
  managed_by  = ".loadout/requires.sh"
  needs_sudo  = true
  run_after   = [program.sudo, script.omalauncher-tracked]
}
