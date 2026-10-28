#!/usr/bin/env zsh
# Tests the tmux function in loadouts/private_dot_config/zsh/plugins/tmux/
# tmux.plugin.zsh together with the scripts it relies on, tmux-ensure-server
# and tmux-server-cwd. Uses the real tmux binary, but on servers of its own:
# TMUX_TMPDIR points every socket into a throwaway directory (kept short:
# a socket path past ~100 characters fails), so this never touches your real
# server. $HOME is a fixture holding the two scripts, so the server a
# bootstrap starts is rooted there. Run: tests/test-tmux-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/loadouts/private_dot_config/zsh/plugins/tmux/tmux.plugin.zsh"
BIN="$SCRIPT_DIR/loadouts/private_dot_local/bin"
WORK="$(mktemp -d)"
export TMUX_TMPDIR="$(mktemp -d /tmp/tpt.XXXX)"
unset TMUX

cleanup() {
  command tmux kill-server >/dev/null 2>&1
  command tmux -L other kill-server >/dev/null 2>&1
  rm -rf -- "${WORK:?}" "${TMUX_TMPDIR:?}"
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])" }

FIXTURE_HOME="$WORK/home"
mkdir -p "$FIXTURE_HOME/.local/bin"
cp "$BIN/executable_tmux-ensure-server" "$FIXTURE_HOME/.local/bin/tmux-ensure-server"
cp "$BIN/executable_tmux-server-cwd" "$FIXTURE_HOME/.local/bin/tmux-server-cwd"
chmod +x "$FIXTURE_HOME/.local/bin/"*
FIXTURE_HOME="${FIXTURE_HOME:A}"
PROJECT="$WORK/project"
mkdir -p "$PROJECT"
PROJECT="${PROJECT:A}"

# Sources the plugin in a fresh zsh started in $1, then runs `tmux "${@:2}"`
# through the function.
run() {
  local dir="$1"; shift
  (cd "$dir" && HOME="$FIXTURE_HOME" PATH="$FIXTURE_HOME/.local/bin:$PATH" PLUGIN="$PLUGIN" \
    zsh -fc 'source "$PLUGIN"; tmux "$@"' _ "$@")
}
sessions() { command tmux list-sessions -F '#S' 2>/dev/null | LC_ALL=C sort | tr '\n' ' ' }
server_cwd() { HOME="$FIXTURE_HOME" "$FIXTURE_HOME/.local/bin/tmux-server-cwd" }
reset() { command tmux kill-server >/dev/null 2>&1; command tmux -L other kill-server >/dev/null 2>&1 }

echo "first start"
run "$PROJECT" new -d -s a
eq "$(sessions)" "_bootstrap a " "creates _bootstrap, then the session asked for"
eq "$(server_cwd)" "$FIXTURE_HOME" "roots the server at \$HOME"
eq "$(command tmux display -p -t a '#{pane_current_path}')" "$PROJECT" "the session opens where it was asked from"
err=$(run "$PROJECT" new -d -s b 2>&1)
eq "$err" "" "a second start is quiet (no duplicate _bootstrap)"
eq "$(sessions)" "_bootstrap a b " "and adds only its own session"
reset

echo "commands that don't start a server"
run "$PROJECT" ls >/dev/null 2>&1
run "$PROJECT" has-session -t x >/dev/null 2>&1
run "$PROJECT" kill-server >/dev/null 2>&1
eq "$(sessions)" "" "ls, has-session and kill-server start nothing"
server_cwd >/dev/null; eq "$?" "1" "tmux-server-cwd exits 1 with no server"

echo "the command past tmux's own options"
run "$PROJECT" -u new -d -s c
eq "$(server_cwd)" "$FIXTURE_HOME" "-u new is guarded"
reset
run "$PROJECT" -2 -f /dev/null new-s -d -s d
eq "$(server_cwd)" "$FIXTURE_HOME" "-2 -f file and the abbreviation new-s are guarded"
reset
run "$PROJECT" -f/dev/null start-server \; new -d -s e
eq "$(server_cwd)" "$FIXTURE_HOME" "-ffile start-server is guarded"
reset

echo "other sockets pass through"
run "$PROJECT" -L other new -d -s f
eq "$(sessions)" "" "-L other starts no default server"
eq "$(command tmux -L other list-sessions -F '#S' 2>/dev/null)" "f" "and leaves the other server alone"
reset

echo "a server running from a deleted folder"
GONE="$WORK/gone"
mkdir -p "$GONE"
(cd "$GONE" && command tmux new-session -d -s old)
rm -rf -- "$GONE"
err=$(run "$PROJECT" new -d -s g 2>&1)
contains "$err" "deleted folder" "warns that only a restart fixes it"
contains "$(server_cwd)" " (deleted)" "tmux-server-cwd shows the deleted folder"
reset

echo "without the scripts"
out=$(HOME="$WORK/empty" PLUGIN="$PLUGIN" zsh -fc 'source "$PLUGIN"; whence -w tmux')
eq "$out" "tmux: command" "no function without tmux-ensure-server"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
