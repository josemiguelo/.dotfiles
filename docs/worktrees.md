# Feature worktrees

Features are developed in workmux worktrees at `../chezmoi__worktrees/<feature>` (`.workmux.yaml`). `workmux add <feature>` starts one from the last commit, so commit `master` first, or pass `-w` to carry uncommitted changes.

chezmoi always reads one source, `chezmoi source-path`: the main checkout's `.chezmoi-home/`, which loadout builds from `master`'s tool folders. Inside a worktree a plain `chezmoi apply` applies `master`, and a plain `chezmoi add` writes into that build, where the next loadout command overwrites it. So use `loadout --repo <worktree> chezmoi …` there: it brings the worktree's own build up to date first and keeps chezmoi's writes in the tool folders (`chezmoi --source <worktree>` reads that build as it is, maybe stale). A fresh worktree has no `.chezmoi-home/` until a loadout command runs in it (`loadout --repo <worktree> repo compile`): chezmoi and `chztry` need one first. The `chz*` shortcuts (`plugins/chezmoi`) do this for the read-only ones (`chzdi`, `chzapnv`) and refuse the others. In Neovim (`features/chezmoi.lua`), a file saved in a worktree isn't auto-applied, and `<leader>sz` lists that worktree's files.

## Trying a feature

In this order of preference (`WT` is the worktree root):

1. `loadout --repo "$WT" chezmoi diff`.
2. `chztry <program> [args…]` from inside the worktree: it renders the worktree, minus scripts and externals, into `$XDG_RUNTIME_DIR/chztry/<feature>` and runs the program with `XDG_CONFIG_HOME`, `ZDOTDIR` and `STARSHIP_CONFIG` pointing there and the preview's `~/.local/bin` first on `PATH` (`chztry nvim`, `zsh`, `tmux`, `kitty`, `yazi`). tmux gets its own server: `chztry tmux kill-server` before trying a changed `tmux.conf` again. A program that reads its config from elsewhere needs its variable added to `chztry`, or rendering by hand: `chezmoi --source "$WT" --destination "$PREVIEW" --persistent-state "$PREVIEW.boltdb" apply --exclude scripts,externals`.
3. `loadout --repo "$WT" chezmoi apply <target>…` for only the targets being tested, for what only works in place (Hyprland, shell startup files).

Never apply a whole worktree: the next apply from `master` reverts its edits, and its new files stay in `$HOME` if the feature is abandoned.

## Finishing or abandoning

- Finish: commit in the worktree (removed paths in their tool's `home/.chezmoiremove`), `workmux merge --cleanup` (rebases onto `master`, removes the worktree, session and branch), then `loadout chezmoi diff` and `loadout config apply` from the main checkout (which also apply the `/` configs), then push.
- Abandon: `workmux remove <feature>` runs `dotfiles-worktree-check` (the `pre_remove` hook), which lists the files only the worktree manages that exist on disk and stops the removal. Delete what shouldn't stay, or set `DOTFILES_CHECK_SKIP=1` to keep them. `loadout config apply` from `master` restores the files the feature changed.

## Paths that outlive the worktree

- Templates never embed `.chezmoi.sourceDir` or a worktree path: the target would point into a deleted worktree.
- A loadout script that writes its own path into a file outside the repo (an Omarchy hook, a command wrapper: `omarchy-theme.ts`, `omarchy-scratchpad-opacity.ts`) takes it from `mainCheckoutPath` (`"loadout/script"`), which gives the main checkout's copy even from a worktree. So a hook installed while trying a feature runs `master`'s copy until the merge (run the worktree's copy by hand to try it). A script new to the feature has no copy on `master` yet, so it writes its worktree path; loadout's `check` on `master` sees the path differ after the merge and installs again.
