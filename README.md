# .dotfiles

My machines in one repo: the dotfiles ([chezmoi](https://www.chezmoi.io/)
reads `configs/`) and everything [loadout](https://github.com/josemiguelo/loadout)
installs, maintains and keeps applied.

## New machine

One command, on a fresh Omarchy, macOS or Fedora install (and on an
omalauncher phone, below):

```bash
curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- <machine>
```

`<machine>` names a machine of the repo (`machines/<machine>.loadout.kt`)
and becomes the hostname (each install keeps its own state file, so a reinstall gets a name of its own, e.g.
`t2-macbook-omarchy-2`). The work laptop is a private child repo's machine
(loadout's contract 18): `bootstrap.sh <machine> --child <ssh url>` keeps its
hostname, clones the child, and sets it up from there. [`bootstrap.sh`](bootstrap.sh) installs git and
chezmoi, sets the hostname, applies the dotfiles over https, installs loadout
and runs `loadout setup-new-machine`; `--dry-run` prints the commands
instead. What it asks for: the sudo password, a passphrase for this machine's
new ssh key (`setup-ssh`), and once, a GitHub login in the browser
(`github-ssh-key` adds the key to the account). Reboot when it's done.

On a fresh Omarchy, run `omarchy update` (or at least `sudo pacman -Sy`)
first: the install leaves pacman without package lists, and installing
chezmoi fails with "target not found".

A machine new to the repo is declared first, compiled and pushed before the
bootstrap reads it: `machine(hostname = "<machine>") { extends(t2Macbook) }`
(or `omarchyProfile`, `macos`, `fedora`) in `machines/<machine>.loadout.kt`,
then `loadout compile` and commit the lock with it. `loadout sync` publishes its state
afterwards (it commits only the state file). To ssh into the T2 laptop from it,
add its name to the key titles `omarchySshd` trusts in
`machines/profiles/t2-macbook.profile.loadout.kt`: the T2 lets in no other key.

### omalauncher (an Android phone)

The Arch that runs inside the omalauncher Android launcher
(`omalauncher-galaxy-a56`, profile `omalauncher`) gets only its own: the
launcher's configs (home layout, style, widgets), a minimal zsh
(`zsh-omalauncher`), mise with java, ruby, claude, codex and try, and widget
sessions (`start-dotfiles-change`, `widgets:`). It's proot as root, with no
systemd and no sudo at first; the same one command sets it up and takes its
own way through the steps for it (its data says `omalauncher`).

1. **Install the launcher and its Linux** (the optional Linux download the
   launcher offers), and open a terminal from it.
2. **Run the bootstrapper** with the phone's machine name:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/josemiguelo/.dotfiles/master/bootstrap.sh | sh -s -- omalauncher-galaxy-a56
   ```
   `--dry-run` after `sh -s --` prints its commands without running them.
   It runs a full `pacman -Syu` (a fresh rootfs may have no package lists),
   installs git and chezmoi with pacman, writes the name to `/etc/hostname`
   before the first apply (chezmoi picks the machine by it, and an unknown one
   gets the desktops' configs; loadout gets it from `LOADOUT_MACHINE`), applies
   the dotfiles, installs loadout, then `loadout install sudo` (loadout asks
   for sudo before any plan that runs it, and the rootfs has none) and
   `loadout setup-new-machine`. Safe to run again: every step skips what's
   done.
3. **Log in to GitHub** when gh asks, the one step by hand: Enter opens the
   Android browser (the launcher's `xdg-open`); type in the one-time code it
   printed and approve. `github-ssh-key` uploads the phone's new key under
   its name, replacing the previous install's.
4. **Open a new terminal**: no reboot; the login shell is zsh now, with
   `LOADOUT_MACHINE` and `LOADOUT_REPO` set.
5. **Look at `git status`** in `~/.local/share/chezmoi`: a fresh launcher's
   own widgets the repo doesn't have are tracked during setup (the launcher's
   files go phone to repo). Keep or drop them, commit what you keep, then
   `loadout sync`.

Values the launcher keeps on the Android side (widgets' `persist` and
`secret` states) don't come back: type the secrets in again. Another phone
is a machine of its own first, as above: `machine(hostname = "<name>") {
extends(omalauncherProfile) }` in `machines/<name>.loadout.kt`, compiled
and pushed before its bootstrap.

## tmux

Scratch terminals come from [tmux-floating-scratchpad](https://github.com/josemiguelo/tmux-floating-scratchpad): prefix `C-t`, one `floating-<session>` per real session. The scratch session stores the parent client's light/dark appearance, because the popup client does not report one. This config maps that onto `COLORFGBG` for programs started there. Prefix `(`/`)` are rebound to [`tmux-session-cycle`](configs/private_dot_local/bin/executable_tmux-session-cycle) so those scratch sessions are skipped; [`tmux-attach`](configs/private_dot_local/bin/executable_tmux-attach) hides them from the picker for the same reason.

## Todos

- omalauncher: a git "dirty" marker in zsh-omalauncher's prompt, worked out in the background (`git status` costs ~230ms there, the prompt ~1ms).
- loadout: ask for sudo after the installs that don't need it, so one `setup-new-machine` can install sudo on omalauncher by itself.

