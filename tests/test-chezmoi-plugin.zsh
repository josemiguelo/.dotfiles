#!/usr/bin/env zsh
# Tests configs/private_dot_config/zsh/plugins/chezmoi/chezmoi.plugin.zsh in
# isolation: a fake `chezmoi` on PATH logs its arguments (and answers
# `source-path` with the fixture source), and the fixture holds a tiny git
# repo as the source, a linked worktree of it and an unrelated repo, all
# inside one mktemp dir. Never touches the real dotfiles, chezmoi or $HOME.
# Run: tests/test-chezmoi-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/configs/private_dot_config/zsh/plugins/chezmoi/chezmoi.plugin.zsh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/chezmoi-plugin-test.XXXXXX")"
WORK="${WORK:A}"

# Deletes only the dir this run created.
cleanup() {
  case "${WORK:?}" in
    "${${TMPDIR:-/tmp}:A}"/chezmoi-plugin-test.*) rm -rf -- "${WORK:?}" ;;
    *) print -u2 "refusing to delete $WORK" ;;
  esac
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])" }

FIXTURE_HOME="$WORK/home"
SRC="$WORK/src"
WT="$WORK/wt"
OTHER="$WORK/other"
FAKEBIN="$WORK/fakebin"
LOG="$WORK/chezmoi-calls.log"
mkdir -p "$FIXTURE_HOME" "$SRC" "$OTHER" "$FAKEBIN"
[[ "$FIXTURE_HOME" == "$WORK"/* ]] || { print -u2 "fixture HOME is not inside $WORK"; exit 1 }

# The fake chezmoi: `source-path` prints the fixture source; anything else is
# logged, one call per line.
printf '%s\n' '#!/usr/bin/env bash' \
  'if [[ "$1" == source-path ]]; then echo "$FAKE_SOURCE"; exit 0; fi' \
  'echo "$*" >> "$CHEZMOI_LOG"' > "$FAKEBIN/chezmoi"
chmod +x "$FAKEBIN/chezmoi"

g() { git -c user.name=test -c user.email=test@example.com "$@" }
export GIT_CONFIG_GLOBAL="$WORK/gitconfig" GIT_CONFIG_NOSYSTEM=1
: > "$GIT_CONFIG_GLOBAL"
g -C "$SRC" init -q -b master
echo a > "$SRC/dot_a"
g -C "$SRC" add -A
g -C "$SRC" commit -qm init
g -C "$SRC" worktree add -q -b feat "$WT"
g -C "$OTHER" init -q -b main

# Calls one of the plugin's functions from directory $1 in a fresh zsh, with
# the fixture HOME/PATH; prints stderr, sets $code.
run() {
  local dir="$1"; shift
  : > "$LOG"
  err=$(cd "$dir" && HOME="$FIXTURE_HOME" PATH="$FAKEBIN:$PATH" FAKE_SOURCE="$SRC" CHEZMOI_LOG="$LOG" \
    PLUGIN="$PLUGIN" zsh -fc 'source "$PLUGIN"; "$@"' _ "$@" 2>&1 >/dev/null)
  code=$?
  calls=$(<"$LOG")
}

for place in "${FIXTURE_HOME}:outside git" "${SRC}:the main source" "${OTHER}:an unrelated repo"; do
  dir=${place%%:*}
  echo "in ${place#*:}: everything runs chezmoi as is"
  run "$dir" chzdi ~/.x;      eq "$calls" "diff $HOME/.x" "chzdi -> chezmoi diff, args passed"
  run "$dir" chzapnv;         eq "$calls" "apply -nv" "chzapnv -> chezmoi apply -nv"
  run "$dir" chzap --force;   eq "$calls" "apply --force" "chzap -> chezmoi apply, args passed"
  run "$dir" chzad ~/.y;      eq "$calls" "add $HOME/.y" "chzad -> chezmoi add"
  run "$dir" chzup;           eq "$calls" "update" "chzup -> chezmoi update"
done

echo "in a feature worktree: read-only ones follow it"
run "$WT" chzdi ~/.x
eq "$calls" "--source $WT diff $HOME/.x" "chzdi -> chezmoi --source <worktree> diff"
eq "$code" 0 "chzdi exits 0"
run "$WT/" chzapnv
eq "$calls" "--source $WT apply -nv" "chzapnv -> chezmoi --source <worktree> apply -nv"

echo "in a feature worktree: the ones that change things refuse"
for fn in chzap chzad chzup; do
  run "$WT" $fn
  eq "$code" 1 "$fn exits 1"
  eq "$calls" "" "$fn never calls chezmoi"
  contains "$err" "would act on master" "$fn says why"
done
contains "$err" "chezmoi --source \"$WT\" apply" "suggests a targeted apply from the worktree"

echo "in a subdirectory of the worktree"
mkdir -p "$WT/sub/dir"
run "$WT/sub/dir" chzdi
eq "$calls" "--source $WT diff" "uses the worktree root, not the subdirectory"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
