# .dotfiles

My machines in one repo: the dotfiles ([chezmoi](https://www.chezmoi.io/)
reads `configs/`) and everything [loadout](https://github.com/josemiguelo/loadout)
installs, maintains and keeps applied.

## New machine

One command, on a fresh Omarchy, macOS or Fedora install:

```bash
curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- <machine>
```

`<machine>` names a machine of the repo (`machines/<machine>.loadout.kt`)
and becomes the hostname (each install keeps its own state file, so a reinstall gets a name of its own, e.g.
`t2-macbook-omarchy-2`). [`bootstrap.sh`](bootstrap.sh) installs git and
chezmoi, sets the hostname, applies the dotfiles over https, installs loadout
and runs `loadout setup-new-machine`; `--dry-run` prints the commands
instead. What it asks for: the sudo password, and once, a GitHub login in the
browser (`github-ssh-key` adds this machine's ssh key to the account). Reboot
when it's done.

On a fresh Omarchy, run `omarchy update` (or at least `sudo pacman -Sy`)
first: the install leaves pacman without package lists, and installing
chezmoi fails with "target not found".

A machine new to the repo is declared first, compiled and pushed before the
bootstrap reads it: `machine(hostname = "<machine>") { extends(t2Macbook) }`
(or `omarchyProfile`, `macos`, `fedora`) in `machines/<machine>.loadout.kt`,
then `loadout compile` and commit the lock with it. `loadout sync` publishes its state
afterwards (it commits only the state file).

## tmux

Scratch terminals come from [tmux-floating-scratchpad](https://github.com/josemiguelo/tmux-floating-scratchpad): prefix `C-t`, one `floating-<session>` per real session. The scratch session stores the parent client's light/dark appearance, because the popup client does not report one. This config maps that onto `COLORFGBG` for programs started there. Prefix `(`/`)` are rebound to [`tmux-session-cycle`](configs/private_dot_local/bin/executable_tmux-session-cycle) so those scratch sessions are skipped; [`tmux-attach`](configs/private_dot_local/bin/executable_tmux-attach) hides them from the picker for the same reason.

## Todos

