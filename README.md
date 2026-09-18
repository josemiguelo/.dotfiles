# .dotfiles

My dotfiles, managed with [chezmoi](https://www.chezmoi.io/).

Install them with:
```bash
chezmoi init --apply --verbose --force https://github.com/josemiguelo/.dotfiles.git
```

## tmux

Scratch terminals come from [tmux-floating-scratchpad](https://github.com/josemiguelo/tmux-floating-scratchpad): prefix `C-t`, one `floating-<session>` per real session. Prefix `(`/`)` are rebound to [`tmux-session-cycle`](private_dot_local/bin/executable_tmux-session-cycle) so those scratch sessions are skipped; [`tmux-attach`](private_dot_local/bin/executable_tmux-attach) hides them from the picker for the same reason.

## Todos

- fix android paths
- nvim navigation (C-hjkl) does not work on terminals (included Snacks) and this breaks TmuxNavigator
- remove custom tmux logic from nvim
- implement asking before quitting on neovim
- clash between Snacks.nvim maximize and definition picker z-index
