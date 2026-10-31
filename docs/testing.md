# Tests

`tests/test-<name>.*` covers the script of that name; a few cover more: `test-tmux-plugin.zsh` also covers `tmux-ensure-server` and `tmux-server-cwd`, `test-tmux-workmux-open.sh` the helper `tmux-attach` and `workmux.plugin.zsh` share, and `test-machine-data.sh` (run after `loadout compile`) the templates' use of the `loadout/machine` partial. After touching one of these, run its test and extend it to cover new behavior; a new script in the same spirit gets a sibling test. Cosmetic changes (comments, icons, wording) need none. These scripts have shipped silent regressions before (an empty picker icon, a bash-4-only builtin on bash 3.2, a popup hijacking the wrong client, zsh's read-only `status` breaking error handling), so treat them as production code.

How they're written:

- The bash tests (`test-tmux-*.sh`) source the script under test (each has a `BASH_SOURCE` guard so sourcing doesn't run its entry point), shadow `tmux()` to send its calls to a throwaway socket, and assert against real tmux and git state.
- The zsh plugin tests run the directly-sourced plugin in a fresh `zsh -c` per case, with `$HOME` and `$PATH` pointed at a throwaway fixture (fake `workmux`, `chezmoi` and `gum` binaries that log their arguments). `test-tmux-plugin.zsh` instead runs the real tmux on servers of its own via `TMUX_TMPDIR`.
- `test-dotfiles-worktree-check.sh` runs the real `chezmoi` against a fixture `$HOME`, source and worktree in one `mktemp` dir.
- Prefer a real dependency over a fake when it's safe (`test-workmux-plugin.zsh` uses the real `gum`).
- Run a test the way its shebang says (`zsh` for `.zsh`), never `source`d into the current shell: this environment's shell is zsh, where a bash script can misbehave silently instead of failing.
