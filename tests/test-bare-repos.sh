#!/usr/bin/env bash
# Tests loadouts/repos/.loadout/bare-repos.ts against a local repo the GitHub
# urls are redirected to: a clone lands bare with its default branch's
# worktree, and a clone left without its worktree is repaired, not reported
# forever. Run: tests/test-bare-repos.sh
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$REPO/loadouts/repos/.loadout/bare-repos.ts"
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT
export LOADOUT_REPO="$REPO" GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
git config --global user.name test
git config --global user.email test@example.com
git init -q -b main "$WORK/widget" && git -C "$WORK/widget" commit -q --allow-empty -m init
git config --global url."$WORK/widget".insteadOf "https://github.com/josemiguelo/widget.git"
export HOME="$WORK/home"
mkdir -p "$HOME"
DIR="$HOME/Repos/gh/josemiguelo/widget"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
run() { loadout bun "$REPO/tests/run-module.ts" "$MODULE" "$1" '{"repos":["widget"]}' > "$WORK/out" 2>&1; }

run check; eq $? 1 "check: not cloned"
run install; eq $? 0 "install: clones"
eq "$(git -C "$DIR" rev-parse --is-bare-repository)" true "the clone is bare"
eq "$(git -C "$DIR/all_worktrees/main" rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)" origin/main "its worktree tracks origin"
eq "$(git -C "$DIR" config remote.origin.pushurl)" git@github.com:josemiguelo/widget.git "it pushes over ssh"
run check; eq $? 0 "check: cloned"

# A clone that failed after `git clone`: the folder, no worktree.
rm -rf -- "${DIR:?}/all_worktrees"
run check; eq $? 1 "check: a clone without its worktree isn't done"
run install; eq $? 0 "install: repairs it"
[[ -d $DIR/all_worktrees/main ]] && ok "the worktree is back" || bad "the worktree is back ($(cat "$WORK/out"))"
run check; eq $? 0 "check: repaired"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
