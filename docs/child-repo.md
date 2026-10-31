# The private child repo

The work laptop is declared by a private child repo of this one (loadout's contract 18; the wiki's Repo-Layout, "A private child repo"), which this repo knows nothing of. The child uses this repo's programs, scripts, profiles and `data` schema by name and adds its own machine, programs and dotfiles; loadout never writes into this repo from it.

- Keep this repo's names stable: a rename here breaks the child's compile (its `sync` recompiles when this repo's manifests change).
- The public side keeps generic hooks the child's dotfiles plug into, no-ops without them: zsh's `conf.d` sources whatever lands there, Neovim imports `lua/overlay` when it exists, `command-palette` reads `<registry>.local`, and the session templates include `~/.config/loadout-session/AGENTS.md` and `allow`.
- A file only the work machine had is removed by the child (its own `.chezmoiremove`), never named here.
- A data key the child needs is a generic one in this repo's `data` schema (like `work`).
- Git's identity is the same on every machine (`setup-git`): the name and GitHub's noreply address. What one machine needs on top, such as a work email for its work repos' folder, goes in `~/.gitconfig.local`, which `~/.gitconfig` includes last; the child ships its own.
