#!/usr/bin/env bash
# Tests loadouts/private_dot_config/.omarchy/.loadout/remove-surfingkeys.ts:
# the Surfingkeys split view extension leaves brave-flags.conf's
# --load-extension line and everything else stays. Each case runs the script
# with XDG_CONFIG_HOME at a fixture. Run: tests/test-remove-surfingkeys.sh

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO/loadouts/private_dot_config/.omarchy/.loadout/remove-surfingkeys.ts"
BUN="$(bun -e 'console.log(process.execPath)')" || { echo "bun not found"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

O=/usr/share/omarchy/default/chromium/extensions
C="$WORK/config"
EXT="$C/surfingkeys/split-view"
FLAGS="$C/brave-flags.conf"
mkdir -p "$C"

# run <mode>: runs the script in mode (check or install), prints its exit code.
run() {
  (cd "$REPO" && XDG_CONFIG_HOME="$C" "$BUN" "$SCRIPT" "$1" >/dev/null 2>&1)
  echo $?
}

echo "split view last on the line"
printf '%s\n' "--ozone-platform=wayland" "--load-extension=$O/copy-url,/x/intentional,$EXT" "--no-default-browser-check" >"$FLAGS"
eq "$(run check)" 1 "check: not done"
eq "$(run install)" 0 "installs"
eq "$(cat "$FLAGS")" "--ozone-platform=wayland
--load-extension=$O/copy-url,/x/intentional
--no-default-browser-check" "only the split view entry gone"
eq "$(run check)" 0 "check: done"

echo "split view in the middle"
printf '%s\n' "--load-extension=$O/copy-url,$EXT,/x/intentional" >"$FLAGS"
eq "$(run install)" 0 "installs"
eq "$(cat "$FLAGS")" "--load-extension=$O/copy-url,/x/intentional" "the others in order"

echo "split view alone on the line"
printf '%s\n' "--ozone-platform=wayland" "--load-extension=$EXT" >"$FLAGS"
eq "$(run install)" 0 "installs"
eq "$(cat "$FLAGS")" "--ozone-platform=wayland" "the empty line dropped"

echo "nothing of Surfingkeys"
printf '%s\n' "--load-extension=$O/copy-url" >"$FLAGS"
eq "$(run check)" 0 "check: done"
eq "$(run install)" 0 "installs"
eq "$(cat "$FLAGS")" "--load-extension=$O/copy-url" "file unchanged"

echo "no flags file"
rm -f "$FLAGS"
eq "$(run check)" 0 "check: done"
eq "$(run install)" 0 "installs"
[[ ! -e "$FLAGS" ]] && ok "no file made" || bad "a file was made"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
