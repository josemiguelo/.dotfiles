#!/usr/bin/env bash
# Tests private_dot_local/bin/executable_tmux-goto in isolation, against a
# throwaway tmux socket — never touches your real tmux server. Every tmux
# call is also logged to a file so assertions can check exact arguments,
# since goto's own output isn't very telling (mostly tmux side effects).
# Fake target/client names don't exist on the test socket, so tmux prints
# "can't find session"/"can't find client" for real; that's expected, not a
# failure — the assertions check the call was made correctly, not that the
# target existed. Run: tests/test-tmux-goto.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/private_dot_local/bin/executable_tmux-goto"
SOCK="tmux-goto-test-$$"
WORK="$(mktemp -d)"
CALLS="$WORK/calls.log"

cleanup() {
  command tmux -L "$SOCK" kill-server >/dev/null 2>&1
  rm -rf "$WORK"
}
trap cleanup EXIT

# Every unqualified `tmux` call goto makes resolves to this function instead
# of the real binary. Logs every call, then either fakes list-clients (when
# FAKE_POPUP_CLIENT is set) or passes through to the isolated test socket.
tmux() {
  echo "$*" >> "$CALLS"
  if [[ "$1" == "list-clients" && -n "${FAKE_POPUP_CLIENT:-}" ]]; then
    echo "$FAKE_POPUP_CLIENT"
    return 0
  fi
  command tmux -L "$SOCK" "$@"
}

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])"; }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])"; }

source "$SCRIPT"

# A persistent session so the test server doesn't exit-empty between calls
# (needed for global options like @floating_target_client to actually stick).
command tmux -L "$SOCK" new-session -d -s _test_anchor

### empty target ###
echo "empty target"

: > "$CALLS"
TMUX=fake goto ""
eq "$(cat "$CALLS")" "" "makes no tmux calls at all"

### outside tmux ###
echo "outside tmux"

: > "$CALLS"
TMUX="" goto "some-session"
contains "$(cat "$CALLS")" "attach-session -t some-session" "attaches directly"

### inside tmux, non-floating session ###
echo "inside tmux, non-floating"

: > "$CALLS"
TMUX=fake goto "some-session" "real-session"
contains "$(cat "$CALLS")" "switch-client -t some-session" "switches the client directly"
not_contains "$(cat "$CALLS")" "detach-client" "does not touch any popup"

### inside tmux, floating session, @floating_target_client set ###
echo "inside the floating scratchpad"

command tmux -L "$SOCK" set-option -g @floating_target_client "the-outer-client"
: > "$CALLS"
FAKE_POPUP_CLIENT="the-popup-client" \
  TMUX=fake goto "some-session" "floating-parent"
contains "$(cat "$CALLS")" "switch-client -c the-outer-client -t some-session" \
  "switches the client that opened the popup, not the popup's own client"
contains "$(cat "$CALLS")" "detach-client -t the-popup-client" \
  "closes the popup by detaching its own client"

### inside tmux, floating session, no popup client found ###
echo "floating scratchpad with no attached popup client"

: > "$CALLS"
unset FAKE_POPUP_CLIENT
TMUX=fake goto "some-session" "floating-parent"
not_contains "$(cat "$CALLS")" "detach-client" "skips detach-client rather than detaching nothing"

### inside tmux, floating session, no @floating_target_client set ###
echo "floating scratchpad with no captured outer client"

command tmux -L "$SOCK" set-option -gu @floating_target_client
: > "$CALLS"
FAKE_POPUP_CLIENT="the-popup-client" \
  TMUX=fake goto "some-session" "floating-parent"
not_contains "$(cat "$CALLS")" "switch-client -c" "skips switching an unknown outer client"
contains "$(cat "$CALLS")" "detach-client -t the-popup-client" "still closes the popup"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
