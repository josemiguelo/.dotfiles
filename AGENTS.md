# Agent instructions

## Git

Only run `git commit` or `git push` when the user explicitly asks to commit or push. Do not infer that from nearby work, “go”, or finishing a task.

If they ask to commit, follow their existing commit style (short lowercase imperative, why over what). If they ask to push, push the current branch. Do neither unless named in that turn.

## Chezmoi

Chezmoi does not delete destination files just because they left the source. Whenever a file or directory is removed from this repo, check whether a corresponding path still exists (or would exist) on a machine after `chezmoi apply`. If it should be destroyed there, add that destination-relative path to `.chezmoiremove`.

