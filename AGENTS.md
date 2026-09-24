# Agent instructions

## Git

Only run `git commit` or `git push` when the user explicitly asks to commit or push. Do not infer that from nearby work, “go”, or finishing a task.

If they ask to commit, follow their existing commit style (short lowercase imperative, why over what). If they ask to push, push the current branch. Do neither unless named in that turn.

## Chezmoi

Chezmoi does not delete destination files just because they left the source. Whenever a file or directory is removed from this repo, check whether a corresponding path still exists (or would exist) on a machine after `chezmoi apply`. If it should be destroyed there, add that destination-relative path to `.chezmoiremove`.

## Testing

Not every change is worth a test — cosmetic ones (comments, icons, wording) aren't. But changes to `tmux-attach`, `tmux-goto`, `tmux-session-cycle`, `android.plugin.zsh`, or `java.plugin.zsh` should be tested: run the matching `tests/test-<name>.sh` after touching any of them, and extend it to cover new behavior (add a sibling `tests/test-<name>.sh` for a new script in the same spirit). These have all shipped real, silent regressions before — a genuinely empty picker icon, a bash-4-only builtin on a bash-3.2 system, a popup hijacking the wrong client — so treat their logic like the production code it is.

The bash scripts (`tests/test-tmux-*.sh`) source the script under test (each has a `BASH_SOURCE` guard so sourcing doesn't run its interactive/top-level entry point), redirect its `tmux` calls to a throwaway socket via a shadowed `tmux()` function so the real server is never touched, and assert against real tmux/git state. The zsh plugin tests (`tests/test-android-plugin.zsh`, `tests/test-java-plugin.zsh`) instead run the (unguarded, directly-sourced) script in a fresh `zsh -c` subshell per case, with `$HOME`/`$PATH` pointed at a throwaway fixture, since these files are meant to be sourced directly on shell startup with no interactive part to guard against.

Match the runner to the file: `.zsh` files use zsh-only syntax (glob qualifiers, `${(q)...}`, `$+commands[...]`) that bash can't even parse, so their tests must run under real zsh — invoke them via their own `#!/usr/bin/env zsh` shebang or `zsh script.sh`, not `source`d into an ambient shell. This matters here specifically: this environment's own interactive shell is zsh, not bash, so a bash script sourced directly into it can silently misbehave (array substitutions in particular) instead of erroring — always exercise a script the same way its shebang says to, not however happens to be convenient.

