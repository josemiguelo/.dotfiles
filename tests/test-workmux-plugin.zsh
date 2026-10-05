#!/usr/bin/env zsh
# Tests configs/private_dot_config/zsh/plugins/workmux/workmux.plugin.zsh in
# isolation: fakes `workmux` (on PATH) and tmux-workmux-open (found via
# $HOME, which is pointed at a fixture) so this never touches your real
# worktrees or tmux state. Covers both the open and add wrapping. Uses the
# real `gum` binary — it's just a spinner around a command, safe to
# exercise for real. Run: tests/test-workmux-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/configs/private_dot_config/zsh/plugins/workmux/workmux.plugin.zsh"
WORK="$(mktemp -d)"

cleanup() { rm -rf -- "${WORK:?}" }
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }
contains() { [[ "$1" == *"$2"* ]] && ok "$3" || bad "$3 (expected to contain [$2], got [$1])" }

# Fixture $HOME with a fake ~/.local/bin/tmux-workmux-open, since the plugin
# calls it by that absolute path (can't be redirected via PATH). It logs its
# invocation instead of actually touching tmux.
FIXTURE_HOME="$WORK/home"
mkdir -p "$FIXTURE_HOME/.local/bin"
OPEN_LOG="$WORK/tmux-workmux-open-calls.log"
cat > "$FIXTURE_HOME/.local/bin/tmux-workmux-open" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$OPEN_LOG"
EOF
chmod +x "$FIXTURE_HOME/.local/bin/tmux-workmux-open"

# A fake `workmux` on PATH: logs every invocation, and for a --headless
# --json call, either prints a fake success receipt or fails, controlled by
# the WORKMUX_HANDLE / WORKMUX_FAIL env vars.
FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
WORKMUX_LOG="$WORK/workmux-calls.log"
cat > "$FAKEBIN/workmux" <<EOF
#!/usr/bin/env bash
echo "\$*" >> "$WORKMUX_LOG"
if [[ "\$*" == *"--headless"* ]]; then
  if [[ -n "\${WORKMUX_FAIL:-}" ]]; then
    echo "simulated headless failure" >&2
    exit 1
  fi
  echo "{\"handle\":\"\${WORKMUX_HANDLE:-fake-handle}\"}"
fi
EOF
chmod +x "$FAKEBIN/workmux"

# Sources the plugin and calls `workmux "$@"` in a fresh subshell, with
# $HOME/$PATH pointed at the fixtures above and $TMUX set to $1.
run() {
  local tmux_val="$1"; shift
  HOME="$FIXTURE_HOME" PATH="$FAKEBIN:$PATH" PLUGIN="$PLUGIN" TMUX="$tmux_val" \
    WORKMUX_HANDLE="${WORKMUX_HANDLE:-}" WORKMUX_FAIL="${WORKMUX_FAIL:-}" \
    zsh -c '
      source "$PLUGIN"
      workmux "$@"
    ' _ "$@"
}

### other subcommands pass straight through ###
echo "passthrough for anything other than add/open"

: > "$WORKMUX_LOG"
run "" list --pr >/dev/null 2>&1
eq "$(cat "$WORKMUX_LOG")" "list --pr" "forwards the subcommand and its args unchanged"
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "" "never touches tmux-workmux-open"

### open, inside tmux: -s inserted, no bootstrap ###
echo "open, inside tmux"

: > "$WORKMUX_LOG"
: > "$OPEN_LOG"
run "fake" open wm-some-branch --continue >/dev/null 2>&1
eq "$(cat "$WORKMUX_LOG")" "open -s wm-some-branch --continue" \
  "calls workmux open -s directly with the rest of the args"
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "" "does not go through tmux-workmux-open (already attached)"

### open, outside tmux: hands off to tmux-workmux-open, forwarding everything ###
echo "open, outside tmux"

: > "$OPEN_LOG"
run "" open wm-a wm-b --continue >/dev/null 2>&1
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "wm-a wm-b --continue" \
  "forwards multiple names and flags to tmux-workmux-open unchanged"

### open from a folder of worktrees: the named worktree's .workmux.yaml is passed ###
# workmux looks for a project config from the cwd, so run from all_worktrees/
# (no repo above it) it would miss wm-cfg's own file. The wrapper passes it.
echo "open, from a folder of worktrees"

WT_DIR="$WORK/all_worktrees"
mkdir -p "$WT_DIR/wm-cfg" "$WT_DIR/wm-plain"
: > "$WT_DIR/wm-cfg/.workmux.yaml"

: > "$WORKMUX_LOG"
(cd "$WT_DIR" && run "fake" open wm-cfg >/dev/null 2>&1)
eq "$(cat "$WORKMUX_LOG")" "open -s --config $WT_DIR/wm-cfg/.workmux.yaml wm-cfg" \
  "inside tmux: passes the named worktree's .workmux.yaml with --config"

: > "$OPEN_LOG"
(cd "$WT_DIR" && run "" open wm-cfg >/dev/null 2>&1)
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "--config $WT_DIR/wm-cfg/.workmux.yaml wm-cfg" \
  "outside tmux: passes the same --config to tmux-workmux-open"

: > "$WORKMUX_LOG"
(cd "$WT_DIR" && run "fake" open wm-plain >/dev/null 2>&1)
eq "$(cat "$WORKMUX_LOG")" "open -s wm-plain" \
  "no .workmux.yaml in the worktree: args are unchanged"

: > "$WORKMUX_LOG"
(cd "$WT_DIR" && run "fake" open --config /other.yaml wm-cfg >/dev/null 2>&1)
eq "$(cat "$WORKMUX_LOG")" "open -s --config /other.yaml wm-cfg" \
  "an explicit --config is left alone"

### inside tmux: -s inserted, rest forwarded, no headless/spinner path ###
echo "add, inside tmux"

: > "$WORKMUX_LOG"
: > "$OPEN_LOG"
run "fake" add some-branch --agent claude >/dev/null 2>&1
eq "$(cat "$WORKMUX_LOG")" "add -s some-branch --agent claude" \
  "calls workmux add -s directly with the rest of the args, no --headless"
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "" "does not go through tmux-workmux-open (already attached)"

### outside tmux: headless creation succeeds, hands off with the right handle ###
echo "add, outside tmux, success"

: > "$WORKMUX_LOG"
: > "$OPEN_LOG"
WORKMUX_HANDLE="wm-some-branch" run "" add some-branch >/dev/null 2>&1
contains "$(cat "$WORKMUX_LOG")" "add --headless --json some-branch" \
  "creates headless first (no tmux backend needed)"
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "wm-some-branch" \
  "hands off to tmux-workmux-open with the handle from workmux's own JSON"

### outside tmux: headless creation fails ###
echo "add, outside tmux, headless failure"

: > "$WORKMUX_LOG"
: > "$OPEN_LOG"
WORKMUX_FAIL=1 run "" add some-branch >/dev/null 2>&1
rc=$?
[[ "$rc" -ne 0 ]] && ok "propagates the failure's exit status" \
  || bad "propagates the failure's exit status (got 0)"
eq "$(cat "$OPEN_LOG" 2>/dev/null)" "" \
  "never hands off to tmux-workmux-open when creation failed"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
