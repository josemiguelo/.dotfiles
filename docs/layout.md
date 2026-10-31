# Where things live

`loadout.hcl` declares the repo (`repo { … }`: state dir, configs dir, version floor, and `sources`, the manifest globs) and the `data { … }` schema (every per-machine setting with its default). `machines/` holds the machines, their profiles and state (`docs/machines.md`). chezmoi reads only `loadouts/`: its special files (`.chezmoiignore`, `.chezmoiremove`, `.chezmoitemplates/`) live there. `.githooks/pre-commit` refuses a commit whose lock is older than its sources (enabled per clone with `git config core.hooksPath .githooks`; `bootstrap.sh` sets it).

## A thing lives where it lands

Everything loadout knows about a tool that lands in `$HOME` sits in chezmoi's source at that spot: `.<tool>.loadout.hcl` (its programs, scripts and their outdated sources) and `.loadout/` (their scripts and files).

- A tool with dotfiles has them beside it: `loadouts/private_dot_config/zsh/.zsh.loadout.hcl`, `loadouts/private_dot_config/.starship.loadout.hcl` beside `starship.toml`.
- A tool without any gets the same spot behind a dot. A one-liner is a file in its destination's parent (`loadouts/private_dot_config/.ripgrep.loadout.hcl`: `~/.config` unless the tool's home is elsewhere, like `loadouts/.ssh/` or `loadouts/private_dot_local/share/.fonts/`); one with scripts or files of its own is a dot-folder named after it (`loadouts/private_dot_config/.ngrok/.ngrok.loadout.hcl` + `.loadout/`). When it gains a config, drop the dot (`git mv .ngrok ngrok`).
- Never a plain folder holding only a manifest: chezmoi creates it, empty, in `$HOME`. Dot entries that aren't chezmoi's own never reach `$HOME`.
- `**` never enters a dot folder, so `sources` globs exactly `loadouts/**/.*.loadout.hcl`, `loadouts/**/.*/.*.loadout.hcl` and `loadouts/.etc/*/.*.loadout.hcl`: a manifest deeper inside a dot folder isn't found.
- Omarchy's own setup of `$HOME` is `loadouts/private_dot_config/.omarchy/` (its shell and bar, overrides, scratchpad, web apps, the `omarchy-<app>` scripts) and `.hypr/` (Hyprland); its setup of Voxtype sits with Voxtype (`.voxtype/.dictation.loadout.hcl`).

## Outside `$HOME`

An app whose work happens outside `$HOME` still lives with the app: virtualization in `.libvirt/`, Omarchy's sshd in `loadouts/.ssh/` beside the client side, omalauncher's fakeroot shim in `private_omalauncher/`, Homebrew in `.homebrew/`. What belongs to no app is in `loadouts/.etc/<concern>/`, the same shape (`.<concern>.loadout.hcl` + `.loadout/`): `.etc/dnf/`, `.etc/pacman/`, `.etc/t2/`, `.etc/keychron/`. So a dot-folder at the root of `loadouts/` is always a place in `$HOME` (`.ssh/`).

## Scripts and helpers

Paths in a manifest are relative to its folder, and its commands run there with `LOADOUT_REPO` set, so moving a file with its scripts needs no edit. Helpers several apps share live in `lib/` (`"$LOADOUT_REPO/lib/…"`); one app's live in its own `.loadout/` (Omarchy's in `.omarchy/.loadout/lib/`, used by `.hypr/` and `.voxtype/` too). A script that also runs outside loadout (an Omarchy hook) reaches them relative to itself (`$HERE/../../../../lib/…`): nothing sets `LOADOUT_REPO` there.

## Homebrew, flatpak, dnf

Every brew installer `requires` setup-brew, and setup-brew `provides "brew" { at = … }`, so brew's `bin` is on `PATH` for every command probed through it on a fresh machine; flatpak (`loadouts/private_dot_local/share/.flatpak.loadout.hcl`) and dnf (`loadouts/.etc/dnf/`) work the same way. Anything else that needs brew by a custom command calls `sh "$LOADOUT_REPO/loadouts/private_dot_config/.homebrew/.loadout/brew.sh" …`.

Homebrew's prefix is decided only in `loadouts/private_dot_local/lib/brew-prefix.sh`: source it and use `$BREW_PREFIX`, never a hardcoded `/opt/homebrew` or `/home/linuxbrew` (loadout's scripts source it from `$LOADOUT_REPO`, since they run before the dotfiles are applied; deployed files from `$HOME`). The one exception is setup-brew's `provides "brew" { at = … }`, which loadout reads without a shell: change it with `brew-prefix.sh`.
