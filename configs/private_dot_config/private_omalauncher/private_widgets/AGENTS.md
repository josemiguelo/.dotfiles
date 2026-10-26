# This machine's rules for the launcher's files

This phone (omalauncher-galaxy-a56) is set up by
[loadout](https://github.com/josemiguelo/loadout) from the dotfiles in
`~/.local/share/chezmoi`, and everything on it is tracked there. Where the
launcher's own instructions (README.md here, /root/CLAUDE.md) say otherwise,
these win.

- **Your edits are tracked by themselves.** Saving a launcher file (a
  top-level `*.owl` here, `../style/style.toml`, `../home/layout.toml`) adds
  it to the dotfiles: in Claude Code a hook does it on every Write or Edit;
  elsewhere run `loadout run --force omalauncher-tracked` (it skips itself
  once it has run, hence `--force`). The hook only sees Claude's own Write
  and Edit, so after any hand edit or another tool's edit, run it, then check
  with `sh ~/.local/share/chezmoi/configs/private_dot_config/private_omalauncher/.loadout/tracked.sh check`:
  no output and exit 0 means nothing is missing. A file deleted here is
  forgotten there the same way. `examples/` and the launcher's dot files
  (`.stock-*`, `.preview/`, ...) are the launcher's, never tracked.
- **A widget's packages go in its `requires { pacman: [...] }`**, and nowhere
  else. Install them with `loadout run omalauncher-requires`, not with
  `pacman -S` as the launcher's docs say: the file is the record of what it
  needs.
- **Anything else** (a program, a setup step, a config outside
  `~/.config/omalauncher`) becomes a loadout program, script or config in
  `~/.local/share/chezmoi`: read its AGENTS.md (the "omalauncher" section)
  first. Never `yay` without asking: here it starts a full system upgrade.
- **When you're done**, `loadout status` shows nothing of yours missing or
  untracked (dotfiles-push stays pending until the user commits).
- **Never commit or push** the dotfiles unless the user asks, in that turn.
