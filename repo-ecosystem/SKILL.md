---
name: repo-ecosystem
description: Map of jochoa's interconnected personal-tooling repos (loadout, .dotfiles, loadout.wiki, skills, and a private local-only repo) and the rule for dispatching cross-repo work into the right one via workmux. Use when this session needs to touch any of these repos.
---

# repo-ecosystem

A map of a small set of interconnected personal-tooling repos, and the rule
for where work on them belongs.

## The repos

- **`~/.local/share/chezmoi`** (josemiguelo/.dotfiles, plain clone) — the
  one config repo. `configs/` is chezmoi's source (`.chezmoiroot`); the rest
  is what `loadout` reads (`LOADOUT_REPO` points here): `loadout.toml`,
  `programs/`, `maintenance/`, `profiles/`, `machines/`, `state/`. A tool's
  loadout fragment sits beside its dotfiles as `.loadout.toml` + `.loadout/`,
  so a change to one tool is one folder and one commit. Plain clone, not
  bare + worktree: it continuously applies one canonical state to the live
  machine, which bare + worktree fits poorly. This skill lives here, at
  `repo-ecosystem/`, because it describes what this repo governs rather
  than being a general-purpose skill; `start-loadout` (zsh) copies it into
  a try session.
- **`~/Repos/gh/josemiguelo/loadout`** (bare + worktree,
  `all_worktrees/<branch>`) — the `loadout` CLI itself (Kotlin/Native):
  installs programs and runs idempotent setup scripts from the config repo.
  A new feature here often needs two follow-ups: a `min-tool-version` bump
  in `.dotfiles`' `loadout.toml`, and a `loadout.wiki` update.
- **`~/Repos/gh/josemiguelo/loadout.wiki`** (plain clone, its own remote) —
  the user-facing wiki. Re-read and update it whenever a loadout change
  touches screen text, keys, repo layout or example output it documents. Its
  live examples link into `.dotfiles` master.
- **`~/Repos/gh/josemiguelo/skills`** (bare + worktree) — general-purpose
  agent skills, symlinked one by one into `~/.claude/skills/<name>` by the
  `skills-repo` script (`.dotfiles` `programs/cli/claude/`) on every machine.
- **A private, local-only repo** exists on at least one machine, outside
  this convention (no shared script clones it); it depends on `.dotfiles`
  and the skills repo.

## The rule

When a task's real home is one of these repos, don't do the work in
whatever scratch or dispatch session you're in. Create a workmux worktree
**in that repo**, from its own default worktree:

```bash
cd ~/Repos/gh/josemiguelo/<loadout|skills>/all_worktrees/<default-branch>
workmux add <branch-name>
```

`.dotfiles` and the wiki are plain clones: edit them directly, no worktree.

A change with a known follow-up in a related repo (a loadout feature needing
a `min-tool-version` bump, or a wiki update) is its own task in that repo —
one worktree never carries changes meant for two repos.
