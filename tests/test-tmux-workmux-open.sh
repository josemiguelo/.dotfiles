#!/usr/bin/env bash
# Tests configs/private_dot_local/bin/executable_tmux-workmux-open: which
# arguments reach `workmux open`. `workmux` and `tmux` are shadowed by fakes on
# PATH that log their arguments, so nothing real is opened or attached. Each
# case runs the script as a fresh process, from a chosen cwd, inside tmux or
# outside it. Run: tests/test-tmux-workmux-open.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/private_dot_local/bin/executable_tmux-workmux-open"
# pwd -P: git reports the real path, and on macOS /var is a link to /private/var.
WORK="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf -- "${WORK:?}"' EXIT

FAKEBIN="$WORK/fakebin"
WORKMUX_LOG="$WORK/workmux.log"
TMUX_LOG="$WORK/tmux.log"
mkdir -p "$FAKEBIN"

# Fake workmux: logs its arguments.
cat > "$FAKEBIN/workmux" <<EOF
#!/bin/sh
echo "\$*" >> "$WORKMUX_LOG"
EOF
# Fake tmux: list-sessions succeeds quietly; new-session logs its arguments.
cat > "$FAKEBIN/tmux" <<EOF
#!/bin/sh
case "\$1" in
  new-session) echo "\$*" >> "$TMUX_LOG" ;;
esac
exit 0
EOF
chmod +x "$FAKEBIN/workmux" "$FAKEBIN/tmux"

# A bare repo with two worktrees in a sibling folder, like all_worktrees/.
# feat-cfg has its own .workmux.yaml; feat-plain doesn't.
REPO="$WORK/repo.git"
git init --bare -q "$REPO"
tmp_seed=$(mktemp -d)
git -C "$tmp_seed" init -q -b main
git -C "$tmp_seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m seed
git -C "$tmp_seed" push -q "$REPO" HEAD:main
rm -rf -- "${tmp_seed:?}"
git -C "$REPO" worktree add -q -b feat-cfg "$WORK/all/feat-cfg" main
git -C "$REPO" worktree add -q -b feat-plain "$WORK/all/feat-plain" main
: > "$WORK/all/feat-cfg/.workmux.yaml"
CFG="$WORK/all/feat-cfg/.workmux.yaml"

# A folder outside any repo, for the no-git case.
mkdir -p "$WORK/loose"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])"; }

# run DIR TMUX_VALUE ARGS...: runs the script from DIR. TMUX_VALUE "" = outside tmux.
run() {
  local dir="$1" tmux_val="$2"; shift 2
  : > "$WORKMUX_LOG"
  : > "$TMUX_LOG"
  if [[ -n "$tmux_val" ]]; then
    (cd "$dir" && PATH="$FAKEBIN:$PATH" HOME="$WORK" TMUX="$tmux_val" bash "$SCRIPT" "$@") >/dev/null 2>&1
  else
    (cd "$dir" && env -u TMUX PATH="$FAKEBIN:$PATH" HOME="$WORK" bash "$SCRIPT" "$@") >/dev/null 2>&1
  fi
}

echo "inside tmux"
run "$REPO" "fake" feat-cfg
eq "$(cat "$WORKMUX_LOG")" "open -s --config $CFG feat-cfg" \
  "a worktree with its own .workmux.yaml: passes it with --config"

run "$REPO" "fake" feat-plain
eq "$(cat "$WORKMUX_LOG")" "open -s feat-plain" \
  "a worktree without its own file: args unchanged"

run "$REPO" "fake" feat-cfg feat-plain
eq "$(cat "$WORKMUX_LOG")" "open -s feat-cfg feat-plain" \
  "several names: args unchanged (one --config would apply to all of them)"

run "$REPO" "fake" --continue
eq "$(cat "$WORKMUX_LOG")" "open -s --continue" \
  "flags only: args unchanged"

run "$REPO" "fake" no-such-worktree
eq "$(cat "$WORKMUX_LOG")" "open -s no-such-worktree" \
  "a name that isn't a worktree of this repo: args unchanged"

run "$WORK/loose" "fake" feat-cfg
eq "$(cat "$WORKMUX_LOG")" "open -s feat-cfg" \
  "outside any git repo: args unchanged, no error"

echo "outside tmux"
run "$REPO" "" feat-cfg
contains "$(cat "$TMUX_LOG")" "workmux open -s --config $CFG feat-cfg" \
  "a worktree with its own .workmux.yaml: the throwaway session's open gets --config"

run "$REPO" "" feat-plain
contains "$(cat "$TMUX_LOG")" "workmux open -s feat-plain" \
  "a worktree without its own file: the throwaway session's open is unchanged"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
