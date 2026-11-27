#!/usr/bin/env zsh
# Tests loadouts/zsh/home/private_dot_config/zsh/plugins/golang/golang.plugin.zsh in a
# fresh `zsh -fc` per case: GOPATH follows the GOROOT mise exports, the
# previous go's bin leaves PATH, nothing is forked (a fake `mise` on PATH logs
# any call), and a shell without go (before setup's later phase) loads fine.
# Run: tests/test-golang-plugin.zsh

PLUGIN="${0:A:h}/../loadouts/zsh/home/private_dot_config/zsh/plugins/golang/golang.plugin.zsh"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/golang-plugin-test.XXXXXX")"
WORK="${WORK:A}"
cleanup() {
  case "${WORK:?}" in
    "${${TMPDIR:-/tmp}:A}"/golang-plugin-test.*) rm -rf -- "${WORK:?}" ;;
    *) print -u2 "refusing to delete $WORK" ;;
  esac
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }

mkdir -p "$WORK/bin"
printf '%s\n' '#!/bin/sh' 'echo "mise $*" >> "$MISE_LOG"' > "$WORK/bin/mise"
chmod +x "$WORK/bin/mise"
LOG="$WORK/mise.log"
GO1="$WORK/installs/go/1.26.0"
GO2="$WORK/installs/go/1.27.1"

# Runs the plugin, then the script in $1, in a fresh zsh; prints what it prints.
run() {
  : > "$LOG"
  env -u GOPATH -u GOROOT PATH="$WORK/bin:/usr/bin:/bin" MISE_LOG="$LOG" PLUGIN="$PLUGIN" ${GOROOT_IN:+GOROOT=$GOROOT_IN} \
    zsh -fc 'source "$PLUGIN"; '"$1" 2>&1
}

echo "with go: GOPATH is GOROOT's"
GOROOT_IN=$GO1
out=$(run 'print -r -- "$GOPATH|${path[-1]}|$GOPRIVATE|${#precmd_functions}"')
eq "$out" "$GO1/packages|$GO1/packages/bin||1" "GOPATH, its bin last on PATH, GOPRIVATE empty, a precmd hook"
eq "$(<"$LOG")" "" "no mise call at startup"

echo "the go in use changes (mise updates GOROOT from its hooks)"
out=$(run 'GOROOT='"$GO2"'; _golang_gopath; print -r -- "$GOPATH"; print -rl -- $path')
eq "${out%%$'\n'*}" "$GO2/packages" "GOPATH follows the new GOROOT"
[[ $out == *"$GO2/packages/bin"* ]] && ok "the new go's bin is on PATH" || bad "the new go's bin is on PATH ($out)"
[[ $out != *"$GO1/packages/bin"* ]] && ok "the old go's bin left PATH" || bad "the old go's bin left PATH ($out)"
out=$(run '_golang_gopath; _golang_gopath; print -rl -- $path | grep -c packages/bin')
eq "$out" "1" "running again adds nothing"
eq "$(<"$LOG")" "" "no mise call from the hook"
out=$(run 'path=(${path:#*/packages/bin}); _golang_gopath; print -rl -- $path | grep -c packages/bin')
eq "$out" "1" "after mise's hook rewrites PATH without it, the hook puts GOPATH/bin back"

echo "without go (before the later phase)"
GOROOT_IN=
out=$(run 'print -r -- "[${GOPATH-unset}]"; print -rl -- $path | grep -c . ')
eq "${out%%$'\n'*}" "[unset]" "GOPATH stays unset"
eq "${out#*$'\n'}" "3" "PATH untouched (no /bin removed by an empty GOPATH)"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
