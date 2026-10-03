#!/usr/bin/env zsh
# Tests configs/private_dot_config/zsh/plugins/gum/gum.plugin.zsh in isolation: a
# fake `gum` on PATH logs its arguments, prints a line and exits with
# $FAKE_GUM_RC. Covers that the function passes arguments, output and exit
# status through. The answers it drops only come from a real terminal
# emulator, so that part is checked by hand (gclone, workmux add outside
# tmux); here stdin isn't a terminal, and nothing may be read from it.
# Run: tests/test-gum-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/configs/private_dot_config/zsh/plugins/gum/gum.plugin.zsh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/gum-plugin-test.XXXXXX")"
WORK="${WORK:A}"

# Deletes only the dir this run created.
cleanup() {
  case "${WORK:?}" in
    "${${TMPDIR:-/tmp}:A}"/gum-plugin-test.*) rm -rf -- "${WORK:?}" ;;
    *) print -u2 "refusing to delete $WORK" ;;
  esac
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }

FAKEBIN="$WORK/fakebin"
LOG="$WORK/gum-calls.log"
mkdir -p "$FAKEBIN"
printf '%s\n' '#!/usr/bin/env bash' \
  'printf "%s|" "$@" >> "$GUM_LOG"; echo >> "$GUM_LOG"' \
  'echo "gum output"' \
  'exit "${FAKE_GUM_RC:-0}"' > "$FAKEBIN/gum"
chmod +x "$FAKEBIN/gum"

# Calls `gum "$@"` through the plugin in a fresh zsh. Stdin is a pipe with
# one line on it, so a read from stdin would consume it: the line left over
# shows nothing was read.
run() {
  : > "$LOG"
  out=$(print "typed" | PATH="$FAKEBIN:$PATH" GUM_LOG="$LOG" FAKE_GUM_RC="${FAKE_GUM_RC:-0}" PLUGIN="$PLUGIN" \
    zsh -fc 'source "$PLUGIN"; gum "$@"; rc=$?; IFS= read -r left; print -r -- "rc=$rc left=$left"' _ "$@")
  calls=$(<"$LOG")
}

echo "gum is a function after loading the plugin"
eq "$(PATH="$FAKEBIN:$PATH" PLUGIN="$PLUGIN" zsh -fc 'source "$PLUGIN"; print -r -- ${+functions[gum]}')" 1 "defines gum"

echo "an interactive command (spin)"
run spin --title "Working..." -- true 'arg with spaces'
eq "$calls" "spin|--title|Working...|--|true|arg with spaces|" "passes every argument through unchanged"
eq "${out%%$'\n'*}" "gum output" "passes gum's output through"
eq "${out##*$'\n'}" "rc=0 left=typed" "exit 0; reads nothing when stdin isn't a terminal"

echo "a failing interactive command (confirm)"
FAKE_GUM_RC=1 run confirm "Sure?"
eq "${out##*$'\n'}" "rc=1 left=typed" "keeps gum's exit status 1"
FAKE_GUM_RC=130 run choose a b
eq "${out##*$'\n'}" "rc=130 left=typed" "keeps gum's exit status 130 (cancelled)"

echo "a non-interactive command (log)"
run log --level info "hello"
eq "$calls" "log|--level|info|hello|" "passes arguments through"
eq "${out##*$'\n'}" "rc=0 left=typed" "exit 0, nothing read"

echo "without gum installed"
eq "$(PATH="/usr/bin/nonexistent" PLUGIN="$PLUGIN" /bin/zsh -fc 'source "$PLUGIN"; print -r -- ${+functions[gum]}')" 0 "defines nothing"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
