#!/usr/bin/env bash
# Tests private_dot_local/bin/executable_dotfiles-worktree-check against a
# throwaway fixture: a fake $HOME, a tiny git repo as the main chezmoi source
# and a linked worktree of it, all inside one mktemp dir. HOME and the XDG
# dirs point there, so the real chezmoi binary only ever sees fixture
# config, state and files; the real home and dotfiles are never touched.
# Run: tests/test-dotfiles-worktree-check.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/private_dot_local/bin/executable_dotfiles-worktree-check"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-worktree-check-test.XXXXXX")"

# Deletes only the dir this run created.
cleanup() {
  case "${WORK:?}" in
    "${TMPDIR:-/tmp}"/dotfiles-worktree-check-test.*) rm -rf -- "${WORK:?}" ;;
    *) echo "refusing to delete $WORK" >&2 ;;
  esac
}
trap cleanup EXIT

export HOME="$WORK/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache" XDG_DATA_HOME="$HOME/.local/share"
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
[[ "$HOME" == "$WORK"/* ]] || { echo "HOME is not inside the fixture" >&2; exit 1; }

SRC="$WORK/src"
WT="$WORK/wt"
mkdir -p "$HOME" "$XDG_CONFIG_HOME/chezmoi" "$SRC"
: > "$GIT_CONFIG_GLOBAL"
printf 'sourceDir = "%s"\n' "$SRC" > "$XDG_CONFIG_HOME/chezmoi/chezmoi.toml"

g() { git -c user.name=test -c user.email=test@example.com "$@"; }
g -C "$SRC" init -q -b master
echo a > "$SRC/dot_a"
g -C "$SRC" add -A
g -C "$SRC" commit -qm init
g -C "$SRC" worktree add -q -b feat "$WT"
chezmoi apply

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])"; }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])"; }

run() { out=$(sh "$SCRIPT" "$@" 2>&1); code=$?; }

echo "worktree that adds nothing"
run "$WT" "$SRC"
eq "$code" 0 "exits 0"
not_contains "$out" "left in" "lists nothing"

echo "worktree with a new file applied to \$HOME, another not applied"
echo new > "$WT/dot_new"
echo never > "$WT/dot_unapplied"
chezmoi --source "$WT" apply "$HOME/.new"
run "$WT" "$SRC"
eq "$code" 1 "exits 1, which stops workmux remove"
contains "$out" "$HOME/.new" "lists the applied file"
not_contains "$out" "$HOME/.unapplied" "skips a target that doesn't exist on disk"
not_contains "$out" "$HOME/.a" "skips a target the main source manages too"

echo "DOTFILES_CHECK_SKIP=1"
out=$(DOTFILES_CHECK_SKIP=1 sh "$SCRIPT" "$WT" "$SRC" 2>&1); code=$?
eq "$code" 0 "exits 0"
contains "$out" "$HOME/.new" "still lists the file"
contains "$out" "going ahead" "says it's leaving them"

echo "worktree that changed a managed file"
echo changed > "$WT/dot_a"
chezmoi --source "$WT" apply "$HOME/.a"
run "$WT" "$SRC"
contains "$out" "differ from" "says managed targets differ from the main source"
contains "$out" ".a" "names the changed target"

echo "the main source given as the worktree"
run "$SRC" "$SRC"
eq "$code" 2 "exits 2"
contains "$out" "is the main source" "says why"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
