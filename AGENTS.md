# Agent instructions

My machines in one public repo: chezmoi's source in `loadouts/` (`.chezmoiroot`; nothing at the root is deployed) and the HCL manifests (`*.loadout.hcl`) that `loadout compile` turns into `loadout.lock.json`, the only thing loadout reads.

## Every change

- Run `git commit` or `git push` only when the user explicitly asks in that turn, never from “go” or a finished task. Commits follow the existing style (short lowercase imperative, why over what); a push pushes the current branch.
- This repo and its history are public: nothing names the employer, its clients, their tools or private repos, nor a work machine or its hostname, and no secret comes in (a token comes from 1Password, `onepasswordRead`). The work laptop is a private child repo's machine; before renaming anything or adding what only it needs, read `docs/child-repo.md`.
- After editing any `.hcl`, run `loadout --repo <checkout> compile` and commit the lock with what it writes (`loadouts/.chezmoidata/loadout.json`, `loadouts/.chezmoitemplates/loadout/`; never edit those by hand). Keep its warnings clean: use what it calls unused, delete it, or say why it stays with `spare = "…"`.
- chezmoi doesn't delete a target whose source is gone: when a removed file should also leave the machines, add its destination path to `loadouts/.chezmoiremove`.
- Before writing a new script, look for one that already does the job, or nearly (`git grep` the setting, file or command; read the neighbours in its `.loadout/` and the shared helpers in `lib/` and `.omarchy/.loadout/lib/`). Reuse it, or extend it when it falls a little short, rather than adding a near copy: Hyprland settings and unbinds go in `.hypr/.loadout/hypr-config/<file>.lua` (`omarchy-hypr-config`), not in a script of their own.
- Templates branch on machine data, never on `.chezmoi.hostname`: `{{ if (includeTemplate "loadout/machine" . | fromJson).omarchy }}`. A new setting is a key in `loadout.hcl`'s `data` schema first. `.chezmoi.os` stays: the OS is a fact, not a setting.
- `setup-new-machine` runs in two phases, core then later (each: programs, then scripts). **Core is a working machine with a functional zsh**: zsh as the login shell and its plugins, tmux with tpack and its plugins, Neovim and its plugins, the shell's CLI tools (starship, atuin, fzf, zoxide, eza, bat), mise with the default version of `node`, `python`, `neovim` and `go` (`args(script.mise-tools, …)`), git, ssh and the GitHub key, 1Password, the hardware fixes, and every step that asks the user something (sudo, a passphrase, a browser login, 1Password's approval), so the slow part needs nobody. `later = "why"` is for what's slow and not needed to work: big app downloads, large Homebrew installs, VMs, SDKs, the other mise versions (`mise-tools-later`), builds from source. A new or changed program or script is core unless it's clearly that; when unsure, ask. Compile refuses a core step that depends on or runs after a later one: never fix that by marking a core item later, and if a later item turns out to be needed for the core, drop its `later`. Check where a change lands with `loadout --repo <worktree> setup-new-machine --dry-run` (later steps print under "Later, after everything above:"), and keep the shell working before the later phase: nothing zsh loads at startup may fail without a later item (guard it, as `plugins/java` and `plugins/android` do).

## In a feature worktree

`LOADOUT_REPO` and `chezmoi source-path` both point at the main checkout, so pass `--repo <worktree>` to every loadout command and `--source "$(git rev-parse --show-toplevel)"` to every chezmoi command. Never apply a whole worktree. Trying, finishing and abandoning a feature: `docs/worktrees.md`.

## More, when the task needs it

- Where a tool's manifest, scripts, files and helpers go: `docs/layout.md`.
- Machines, profiles, their lists and machine names: `docs/machines.md`.
- Changing a script that has a `tests/test-<name>.*`: run it and extend it; how they're written in `docs/testing.md`.
- The omalauncher phone (`omalauncher-galaxy-a56`) or anything it gets: `docs/omalauncher.md`.
- The T2 MacBook (`t2-macbook-omarchy`): `docs/t2-macbook.md`, and read it before anything that reinstalls, upgrades or migrates Omarchy there.
- loadout's manifest language (`via`, `variant`, `args`, `requires`, `provides`, child repos): the loadout wiki, `Writing-Your-Manifest` and `Repo-Layout`, cloned at `~/Repos/gh/josemiguelo/loadout.wiki`.
