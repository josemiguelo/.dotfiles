# .dotfiles

My machines in one repo: the dotfiles ([chezmoi](https://www.chezmoi.io/)
reads `configs/`) and everything [loadout](https://github.com/josemiguelo/loadout)
installs, maintains and keeps applied.

## New machine

1. Install git and chezmoi (Omarchy ships both; macOS and Fedora:
   `brew install chezmoi`).
2. Omarchy only: move its pre-installed Neovim config aside, or its plugins
   load under ours (chezmoi only replaces the files it manages):
   ```bash
   mv ~/.config/nvim ~/.config/nvim.pre-chezmoi
   ```
3. Give back anything under `~/.local` a root-run installer left owned by
   root (prints nothing when all is yours):
   ```bash
   find ~/.local ! -user "$USER" -print0 | xargs -0 -r sudo chown "$USER:$(id -gn)"
   ```
4. Clone the repo (https: this machine may have no ssh key yet;
   `dotfiles-ssh-remote` switches the checkout to ssh later):
   ```bash
   chezmoi init https://github.com/josemiguelo/.dotfiles.git
   ```
5. A machine new to the repo gets its file before the first apply, since
   the templates read it: `~/.local/share/chezmoi/machines/$(hostname).yaml`
   with `extends = ["omarchy"]`, `["macos"]` or `["fedora"]`.
6. Apply the dotfiles, install loadout, and open a new shell (the
   dotfiles set `LOADOUT_REPO`):
   ```bash
   chezmoi apply
   curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh
   ```
7. `loadout setup-new-machine`. Commit the new machine file yourself
   (`sync` commits only the state file), then `loadout sync` publishes both.

## tmux

Scratch terminals come from [tmux-floating-scratchpad](https://github.com/josemiguelo/tmux-floating-scratchpad): prefix `C-t`, one `floating-<session>` per real session. The scratch session stores the parent client's light/dark appearance, because the popup client does not report one. This config maps that onto `COLORFGBG` for programs started there. Prefix `(`/`)` are rebound to [`tmux-session-cycle`](configs/private_dot_local/bin/executable_tmux-session-cycle) so those scratch sessions are skipped; [`tmux-attach`](configs/private_dot_local/bin/executable_tmux-attach) hides them from the picker for the same reason.

## Todos

