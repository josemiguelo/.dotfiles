# Agent instructions

## Git

Only run `git commit` or `git push` when the user explicitly asks to commit or push. Do not infer that from nearby work, “go”, or finishing a task.

If they ask to commit, follow their existing commit style (short lowercase imperative, why over what). If they ask to push, push the current branch. Do neither unless named in that turn.

## Chezmoi

Chezmoi does not delete destination files just because they left the source. Whenever a file or directory is removed from this repo, check whether a corresponding path still exists (or would exist) on a machine after `chezmoi apply`. If it should be destroyed there, add that destination-relative path to `.chezmoiremove`.

### Feature worktrees

Features are developed in workmux worktrees beside the source, at `../chezmoi__worktrees/<feature>` (set in `.workmux.yaml`). chezmoi always reads one source, `chezmoi source-path` (the main checkout, on `master`), whatever the current directory. So inside a worktree, a plain `chezmoi apply` applies `master`, and `chezmoi add` writes into `master`'s checkout. Inside a worktree (when `git rev-parse --show-toplevel` differs from `chezmoi source-path`), pass `--source "$(git rev-parse --show-toplevel)"` to every chezmoi command.

To try a feature, prefer `chezmoi --source … diff`, an apply into a scratch `--destination "$(mktemp -d)"`, or applying only the targets being tested. A full apply from a worktree has two side effects: the next apply from `master` reverts its edits, and its new files stay in `$HOME` if the feature is abandoned. `workmux remove` runs `dotfiles-worktree-check` (the `pre_remove` hook), which lists the files only the worktree manages that exist on disk and stops the removal. Delete what shouldn't stay, or set `DOTFILES_CHECK_SKIP=1` to keep them.

## Testing

Not every change is worth a test — cosmetic ones (comments, icons, wording) aren't. But changes to `tmux-attach`, `tmux-goto`, `tmux-session-cycle`, `android.plugin.zsh`, `java.plugin.zsh`, or `workmux.plugin.zsh` should be tested: run the matching `tests/test-<name>.sh` after touching any of them, and extend it to cover new behavior (add a sibling `tests/test-<name>.sh` for a new script in the same spirit). These have all shipped real, silent regressions before — a genuinely empty picker icon, a bash-4-only builtin on a bash-3.2 system, a popup hijacking the wrong client, `status` being a read-only special variable in zsh that silently broke a function's error handling — so treat their logic like the production code it is. `tmux-workmux-open` (the bootstrap helper shared by `tmux-attach` and `workmux.plugin.zsh`) has no test file of its own: its logic is a strict subset of what `tests/test-tmux-attach.sh`'s "extracts the handle" case already exercises for real, and `tests/test-workmux-plugin.zsh` exercises the handoff to it via a fixture stub.

The bash scripts (`tests/test-tmux-*.sh`) source the script under test (each has a `BASH_SOURCE` guard so sourcing doesn't run its interactive/top-level entry point), redirect its `tmux` calls to a throwaway socket via a shadowed `tmux()` function so the real server is never touched, and assert against real tmux/git state. The zsh plugin tests (`tests/test-android-plugin.zsh`, `tests/test-java-plugin.zsh`, `tests/test-workmux-plugin.zsh`) instead run the (unguarded, directly-sourced) script in a fresh `zsh -c` subshell per case, with `$HOME`/`$PATH` (and for workmux, a fake `workmux` on `$PATH` plus a fake `tmux-workmux-open` under the fixture `$HOME`) pointed at a throwaway fixture, since these files are meant to be sourced directly with no interactive part to guard against. Prefer exercising a real dependency over faking it when it's safe to (`test-workmux-plugin.zsh` uses the real `gum` binary — it's just a spinner around a command).

Match the runner to the file: `.zsh` files use zsh-only syntax (glob qualifiers, `${(q)...}`, `$+commands[...]`) that bash can't even parse, so their tests must run under real zsh — invoke them via their own `#!/usr/bin/env zsh` shebang or `zsh script.sh`, not `source`d into an ambient shell. This matters here specifically: this environment's own interactive shell is zsh, not bash, so a bash script sourced directly into it can silently misbehave (array substitutions in particular) instead of erroring — always exercise a script the same way its shebang says to, not however happens to be convenient.

