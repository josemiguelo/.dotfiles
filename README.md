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

### omalauncher (an Android phone)

The Arch that runs inside the omalauncher Android launcher
(`omalauncher-galaxy-a56`, profile `omalauncher`) gets only its own: the
launcher's configs (home layout, style, widgets), a minimal zsh
(`zsh-omalauncher`), and mise with java, ruby, claude, codex and try. It's
proot as root, with no systemd and no sudo at first, so `bootstrap.sh` doesn't
fit it; in a launcher terminal:

```bash
pacman -Qu   # nothing pending, or pacman -Syu first: never a partial upgrade
cp -p /etc/hostname /etc/hostname.pre-loadout; echo omalauncher-galaxy-a56 > /etc/hostname
pacman -S --needed --noconfirm git chezmoi
chezmoi init --apply https://github.com/josemiguelo/.dotfiles.git
git -C ~/.local/share/chezmoi config core.hooksPath .githooks
curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh
export PATH=$HOME/.local/bin:$PATH
loadout --repo ~/.local/share/chezmoi --machine omalauncher-galaxy-a56 install sudo --yes
loadout --repo ~/.local/share/chezmoi --machine omalauncher-galaxy-a56 setup-new-machine --yes
loadout --repo ~/.local/share/chezmoi --machine omalauncher-galaxy-a56 sync
```

The hostname goes first: chezmoi picks the machine by `/etc/hostname`, and an
unknown one gets the desktops' configs. sudo goes before the rest because
loadout asks for it before any plan that runs it. gh's login opens the Android
browser (the launcher's `xdg-open`); new shells are zsh, with `LOADOUT_MACHINE`
and `LOADOUT_REPO` set.

## tmux

Scratch terminals come from [tmux-floating-scratchpad](https://github.com/josemiguelo/tmux-floating-scratchpad): prefix `C-t`, one `floating-<session>` per real session. The scratch session stores the parent client's light/dark appearance, because the popup client does not report one. This config maps that onto `COLORFGBG` for programs started there. Prefix `(`/`)` are rebound to [`tmux-session-cycle`](configs/private_dot_local/bin/executable_tmux-session-cycle) so those scratch sessions are skipped; [`tmux-attach`](configs/private_dot_local/bin/executable_tmux-attach) hides them from the picker for the same reason.

## Todos

- omalauncher: a git "dirty" marker in zsh-omalauncher's prompt, worked out in the background (`git status` costs ~230ms there, the prompt ~1ms).
- loadout: ask for sudo after the installs that don't need it, so one `setup-new-machine` can install sudo on omalauncher by itself.
- omalauncher: a face for the empty home page left of the others (`page: -2`), still to be decided.

