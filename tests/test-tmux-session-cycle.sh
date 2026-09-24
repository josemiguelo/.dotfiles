#!/usr/bin/env bash
# Tests private_dot_local/bin/executable_tmux-session-cycle in isolation,
# against a throwaway tmux socket — never touches your real tmux server.
# Run: tests/test-tmux-session-cycle.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/private_dot_local/bin/executable_tmux-session-cycle"
SOCK="tmux-cycle-test-$$"

cleanup() { command tmux -L "$SOCK" kill-server >/dev/null 2>&1; }
trap cleanup EXIT

# Every unqualified `tmux` call resolves to this function instead of the real
# binary, since shell functions take precedence over PATH lookups.
tmux() { command tmux -L "$SOCK" "$@"; }

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

source "$SCRIPT"

### collect_cycle_sessions ###
echo "collect_cycle_sessions"

tmux new-session -d -s alpha
tmux new-session -d -s beta
tmux new-session -d -s "floating-alpha"
tmux new-session -d -s _bootstrap
collect_cycle_sessions
eq "${sessions[*]}" "alpha beta" "excludes floating-* and _bootstrap sessions"

### next_target: plain next/prev with wraparound ###
echo "next_target: cycling"

sessions=(a b c)
eq "$(next_target next b)" "c" "next from the middle session"
eq "$(next_target prev b)" "a" "prev from the middle session"
eq "$(next_target next c)" "a" "next wraps from the last session to the first"
eq "$(next_target prev a)" "c" "prev wraps from the first session to the last"

### next_target: current session not in the list ###
echo "next_target: current session not found"

eq "$(next_target next zzz)" "a" "falls back to the first session"
eq "$(next_target prev zzz)" "a" "falls back to the first session regardless of direction"

### next_target: no sessions at all ###
echo "next_target: empty session list"

sessions=()
next_target next current
eq "$?" "1" "returns failure so main can exit cleanly instead of switching nowhere"

### next_target: a single session ###
echo "next_target: one session"

sessions=(only)
eq "$(next_target next only)" "only" "cycling with one session targets itself"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
