#!/usr/bin/env bash
# Tests private_dot_local/bin/executable_tmux-attach in isolation: a shadowed
# `tmux` function redirects every call the script makes to a throwaway test
# socket, so this never touches your real tmux server or sessions. `zoxide`
# and `workmux` are shadowed too, for deterministic input and to avoid
# depending on what's actually installed. Run: tests/test-tmux-attach.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/private_dot_local/bin/executable_tmux-attach"
SOCK="tmux-attach-test-$$"
WORK="$(mktemp -d)"

cleanup() {
  tmux -L "$SOCK" kill-server >/dev/null 2>&1
  rm -rf "$WORK"
}
trap cleanup EXIT

# Every unqualified `tmux` call the script makes resolves to this function
# instead of the real binary, since shell functions take precedence over
# PATH lookups. No changes to the script needed.
tmux() { command tmux -L "$SOCK" "$@"; }

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])"; }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])"; }

# Source the script under test. The BASH_SOURCE guard keeps `main` (and the
# interactive fzf-tmux call) from running.
source "$SCRIPT"

### ensure_server_home ###
echo "ensure_server_home"

ensure_server_home
server_cwd=$(lsof -a -p "$(tmux display-message -p '#{pid}')" -d cwd -Fn 2>/dev/null | sed -n 's/^n//p')
eq "$server_cwd" "$HOME" "spawns a fresh server rooted at \$HOME"
contains "$(tmux list-sessions -F '#S' 2>/dev/null)" "_bootstrap" "creates the _bootstrap session"

before=$(tmux list-sessions -F '#S' 2>/dev/null | wc -l | tr -d ' ')
ensure_server_home
after=$(tmux list-sessions -F '#S' 2>/dev/null | wc -l | tr -d ' ')
eq "$after" "$before" "is a no-op once a server is already running"

### collect_sessions ###
echo "collect_sessions"

tmux new-session -d -s real-one -c "$WORK"
tmux new-session -d -s "floating-real-one" -c "$WORK"
collect_sessions
contains "$sessions" "real-one" "lists a real session"
not_contains "$sessions" "floating-real-one" "excludes floating-* scratchpad sessions"
not_contains "$sessions" "_bootstrap" "excludes the _bootstrap session"

### _has_session_for ###
echo "_has_session_for"

open_names=$'foo\nbar baz'
_has_session_for "foo" && ok "matches an exact session name" || bad "matches an exact session name"
_has_session_for "baz" && ok "matches a glyph-prefixed \" <name>\" suffix" || bad "matches a glyph-prefixed \" <name>\" suffix"
_has_session_for "nope" && bad "does not match an unrelated name" || ok "does not match an unrelated name"

### collect_dirs ###
echo "collect_dirs"

tmux kill-server >/dev/null 2>&1
tmux new-session -d -s existing-dir -c "$WORK"
collect_sessions # refresh open_names for the new session state
zoxide() { printf '%s\n' "/some/path/existing-dir" "/some/path/new-dir"; }
collect_dirs
not_contains "$dirs" "existing-dir" "hides a dir whose session already exists"
contains "$dirs" "new-dir" "shows a dir with no session yet"
unset -f zoxide

### collect_worktrees ###
echo "collect_worktrees"

REPO="$WORK/repo"
git init --bare -q "$REPO"
# A bare repo has no commits yet; seed one via a throwaway clone so `main`
# is a real ref both worktrees below can be based on.
tmp_seed=$(mktemp -d)
git -C "$tmp_seed" init -q -b main
git -C "$tmp_seed" -c user.email=t@t -c user.name=t commit -q --allow-empty -m seed
git -C "$tmp_seed" push -q "$REPO" HEAD:main
rm -rf "$tmp_seed"
git -C "$REPO" worktree add -q "$WORK/main-wt" main
git -C "$REPO" worktree add -q -b feature "$WORK/feature-wt" main

workmux() { :; }
cd "$REPO"
current_session=""
collect_worktrees
cd - >/dev/null
contains "$worktrees" "repo main-wt" "lists a worktree, prefixed with the project name"
contains "$worktrees" "repo feature-wt" "lists a second worktree"

tmux new-session -d -s "repo feature-wt" -c "$WORK"
collect_sessions # refresh open_names
cd "$REPO"
collect_worktrees
cd - >/dev/null
not_contains "$worktrees" "feature-wt" "hides a worktree whose session already exists"

cd "$REPO"
current_session="floating-something"
collect_worktrees
cd - >/dev/null
eq "$worktrees" "" "returns nothing from inside the floating scratchpad"
current_session=""

unset -f workmux
cd "$REPO"
PATH=/usr/bin:/bin collect_worktrees # a PATH without workmux's real location
cd - >/dev/null
eq "$worktrees" "" "returns nothing when workmux isn't available"

### divider ###
echo "divider"

eq "$(divider "" "x")" "" "empty when there's nothing above"
eq "$(divider "x" "")" "" "empty when there's nothing below"
contains "$(divider "x" "y")" "─" "drawn when there's something on both sides"

# main()'s guard checks for this same character, so a picked divider line
# no-ops instead of falling through to determine_target as a bogus choice.
choice=$(divider "x" "y")
[[ "$choice" == *'─'* ]]
eq "$?" "0" "divider output matches main()'s no-op guard"

# pick()'s actual calls: sessions/(worktrees+dirs), and worktrees/dirs.
sessions="a" worktrees="" dirs="b"
contains "$(divider "$sessions" "$worktrees$dirs")" "─" \
  "sessions/worktrees+dirs divider counts dirs alone as something after sessions"

worktrees="" dirs="x"
eq "$(divider "$worktrees" "$dirs")" "" \
  "worktrees/dirs divider empty when worktrees alone is missing"

worktrees="x" dirs=""
eq "$(divider "$worktrees" "$dirs")" "" \
  "worktrees/dirs divider empty when dirs alone is missing"

worktrees="x" dirs="y"
contains "$(divider "$worktrees" "$dirs")" "─" \
  "worktrees/dirs divider drawn when both are present"

### section_binds ###
echo "section_binds"

sessions="s1" worktrees="" dirs=""
eq "$(section_binds)" "" "empty when only one section has entries -- nothing to move between"

sessions="" worktrees="" dirs=""
eq "$(section_binds)" "" "empty when nothing has entries"

# Runs an emitted bind's transform body for real, under sh -c (what fzf
# actually uses for transform commands, NOT bash -- this is what caught the
# original bug: pos($s) parses fine in bash but is a syntax error in sh,
# which reads a bare word immediately followed by "(" as an attempted
# function definition. A plain string-contains check on the bind text
# would never have caught that; only actually running it does.
run_transform() {
  local binds="$1" key="$2" n="$3" body
  body=$(printf '%s\n' "$binds" | grep "^$key:transform:" | sed "s/^$key:transform://")
  body="${body//\{n\}/$n}"
  sh -c "$body"
}

sessions=$(printf 's1\ns2\ns3\n')
worktrees=$(printf 'w1\nw2\n')
dirs=$(printf 'd1\nd2\nd3\nd4\n')
binds=$(section_binds)
# Layout (1-indexed): s1=1 s2=2 s3=3 div=4 w1=5 w2=6 div=7 d1=8 d2=9 d3=10 d4=11
# {n} is 0-indexed, so e.g. n=0 is s1, n=4 is w1, n=7 is d1.
eq "$(run_transform "$binds" ctrl-j 0)" "pos(5)" "ctrl-j from sessions goes to worktrees"
eq "$(run_transform "$binds" ctrl-j 4)" "pos(8)" "ctrl-j from worktrees goes to dirs"
eq "$(run_transform "$binds" ctrl-j 7)" "pos(1)" "ctrl-j from dirs wraps around to sessions"
eq "$(run_transform "$binds" ctrl-k 1)" "pos(8)" \
  "ctrl-k from the MIDDLE of sessions (not its own start) wraps to dirs, not back to sessions itself"
eq "$(run_transform "$binds" ctrl-k 4)" "pos(1)" "ctrl-k from worktrees' own start goes to sessions"
eq "$(run_transform "$binds" ctrl-k 7)" "pos(5)" "ctrl-k from dirs' own start goes to worktrees"

sessions="" worktrees="w1" dirs="d1"
binds=$(section_binds)
# Layout: w1=1 div=2 d1=3
eq "$(run_transform "$binds" ctrl-j 0)" "pos(3)" "ctrl-j with no sessions goes straight to dirs"
eq "$(run_transform "$binds" ctrl-k 0)" "pos(3)" "ctrl-k with no sessions wraps to dirs (only 2 sections exist)"

### determine_target ###
echo "determine_target"

# determine_target's worktree branch execs the real ~/.local/bin/tmux-workmux-open
# (an absolute path, so it can't be faked via PATH), which itself execs
# `workmux` as a bare command — a `workmux() { ... }` function stub would be
# silently ignored either way (exec only does PATH lookups), so fake it as a
# real executable on PATH instead. It also redirects workmux's own stdout to
# /dev/null, so the fake records the call to a file rather than printing it.
# Known gap: tmux-workmux-open's own `tmux list-sessions` check right before
# the exec chain still hits the real tmux server (harmless and read-only,
# since a real server is always running here, but not fully hermetic).
FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
CALL_LOG="$WORK/workmux-call.log"
cat >"$FAKEBIN/workmux" <<FAKE
#!/usr/bin/env bash
echo "\$*" > "$CALL_LOG"
FAKE
chmod +x "$FAKEBIN/workmux"
choice="$worktree_icon repo feature-wt"
TMUX=fake
(PATH="$FAKEBIN:$PATH" determine_target) >/dev/null 2>&1
contains "$(cat "$CALL_LOG" 2>/dev/null)" "open -s feature-wt" "extracts the handle (last word) and opens it with -s"
TMUX=""

choice="$session_icon existing-dir"
determine_target
eq "$target" "existing-dir" "an existing-session choice sets target directly"

choice="$dir_icon $WORK/brand-new-dir"
mkdir -p "$WORK/brand-new-dir"
determine_target
eq "$target" "brand-new-dir" "a new-directory choice derives target from its basename"
contains "$(tmux list-sessions -F '#S' 2>/dev/null)" "brand-new-dir" "and creates a session for it"

choice="$dir_icon $WORK/main-wt"
before=$(tmux list-sessions -F '#S' 2>/dev/null | wc -l | tr -d ' ')
tmux new-session -d -s main-wt -c "$WORK"
determine_target
after=$(tmux list-sessions -F '#S' 2>/dev/null | wc -l | tr -d ' ')
eq "$target" "main-wt" "a directory choice matching an existing session reuses it"
eq "$after" "$((before + 1))" "without creating a duplicate"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
