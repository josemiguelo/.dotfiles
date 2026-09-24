# Agent instructions

## Git

Only run `git commit` or `git push` when the user explicitly asks to commit or push. Do not infer that from nearby work, “go”, or finishing a task.

If they ask to commit, follow their existing commit style (short lowercase imperative, why over what). If they ask to push, push the current branch. Do neither unless named in that turn.

## Chezmoi

Chezmoi does not delete destination files just because they left the source. Whenever a file or directory is removed from this repo, check whether a corresponding path still exists (or would exist) on a machine after `chezmoi apply`. If it should be destroyed there, add that destination-relative path to `.chezmoiremove`.

## Testing

Not every change is worth a test — cosmetic ones (comments, icons, wording) aren't. But changes to `tmux-attach`, `tmux-goto`, or `tmux-session-cycle` should be tested: run `tests/test-tmux-attach.sh` after touching any of them, and extend it (or add a sibling `tests/test-<name>.sh`) to cover new behavior. These scripts have shipped real, silent regressions before, so treat their logic like the production code it is. See `tests/test-tmux-attach.sh` for the pattern: source the script (guarded so sourcing doesn't run the interactive picker), redirect its `tmux` calls to a throwaway socket via a shadowed `tmux()` function so the real server is never touched, and assert against real tmux/git state.

