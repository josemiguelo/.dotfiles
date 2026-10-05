#!/usr/bin/env bash
# Tests configs/private_dot_local/bin/executable_kitty-tmux-attach's choice of
# start directory: the pane of the tmux client that runs in the kitty window the
# overlay was opened from, not whichever client tmux considers current. kitty
# and tmux are shadowed with functions, so this never touches real windows or
# sessions. Run: tests/test-kitty-tmux-attach.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/private_dot_local/bin/executable_kitty-tmux-attach"

# Sourcing stops before the exec at the bottom of the script (its BASH_SOURCE guard).
source "$SCRIPT"

# Fake kitty: prints $KITTY_JSON, or fails when KITTY_FAIL is set (remote control off).
kitty() {
  [[ -z "${KITTY_FAIL:-}" ]] || return 1
  printf '%s' "$KITTY_JSON"
}

# Fake tmux: two attached clients, each on its own tty with its own pane path.
# TMUX_NO_SERVER makes list-clients fail, as it does with no server running.
tmux() {
  case "$1" in
  list-clients)
    [[ -z "${TMUX_NO_SERVER:-}" ]] || return 1
    printf '%s\n' "999 /dev/ttys005" "4242 /dev/ttys009"
    ;;
  display-message)
    # called as: display-message -p -c <tty> '#{pane_current_path}'
    case "$4" in
    /dev/ttys009) echo /Users/x/cobranded ;;
    /dev/ttys005) echo /Users/x/tries ;;
    esac
    ;;
  esac
}

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

# kitty @ ls --match state:overlay_parent output, shaped like kitty's
# (os_windows > tabs > windows > foreground_processes).
PARENT_JSON='[{"tabs":[{"windows":[{"id":6,"foreground_processes":[{"pid":4242,"cmdline":["tmux","attach"]}]}]}]}]'
SHELL_JSON='[{"tabs":[{"windows":[{"id":6,"foreground_processes":[{"pid":111,"cmdline":["zsh"]}]}]}]}]'

echo "parent_pane_path"

KITTY_JSON="$PARENT_JSON"
eq "$(parent_pane_path)" "/Users/x/cobranded" \
  "parent window's tmux client: uses that client's pane, not the other client's"

KITTY_JSON="$SHELL_JSON"
eq "$(parent_pane_path)" "" "parent window running no tmux client: empty (caller falls back to PWD)"

KITTY_JSON="$PARENT_JSON"
KITTY_FAIL=1
eq "$(parent_pane_path)" "" "kitty remote control unavailable: empty"
unset KITTY_FAIL

KITTY_JSON="$PARENT_JSON"
TMUX_NO_SERVER=1
eq "$(parent_pane_path)" "" "no tmux server: empty"
unset TMUX_NO_SERVER

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
