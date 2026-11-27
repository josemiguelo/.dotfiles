#!/usr/bin/env bash
# Tests loadouts/atuin/.loadout/login.ts with a fake atuin:
# what counts as logged in, the retries on a terminal, the wait without one,
# and a failed first sync logged out again. Run: tests/test-atuin-login.sh
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGIN="$REPO/loadouts/atuin/.loadout/login.ts"
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT
mkdir -p "$WORK/bin"
# State in $WORK: in (logged in), offline, badsync; succeed-at: the login try that works.
cat > "$WORK/bin/atuin" <<'F'
#!/usr/bin/env bash
W="$(cd "$(dirname "$0")/.." && pwd)"
echo "$1" >> "$W/log"
case "$1" in
status)
  [[ -e $W/in ]] || { echo "Error: You are not logged in to a sync server - cannot show sync status" >&2; exit 1; }
  [[ ! -e $W/offline ]] || { echo "Error: error sending request for url" >&2; exit 1; } ;;
login)
  (( $(grep -c login "$W/log") >= $(cat "$W/succeed-at") )) || exit 1
  touch "$W/in" ;;
sync) [[ ! -e $W/badsync ]] ;;
logout) rm -f "$W/in" ;;
esac
F
chmod +x "$WORK/bin/atuin"
export PATH="$WORK/bin:$PATH" LOADOUT_REPO="$REPO"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
reset() { rm -f "$WORK"/{in,offline,badsync,log}; echo "${1:-1}" > "$WORK/succeed-at"; touch "$WORK/log"; }
count() { grep -c "^$1\$" "$WORK/log"; }
login() { loadout bun "$REPO/tests/run-module.ts" "$LOGIN" "$@" > "$WORK/out" 2>&1 < /dev/null; }
on_tty() { script -qec "loadout bun $REPO/tests/run-module.ts $LOGIN install" /dev/null > "$WORK/out" 2>&1 < /dev/null; }

reset; login check; eq $? 1 "check: logged out"
touch "$WORK/in"; login check; eq $? 0 "check: logged in"
touch "$WORK/offline"; login check; eq $? 0 "check: offline isn't logged out"

reset 1; on_tty; eq "$? $(count login) $(count sync)" "0 1 1" "terminal: logs in, then syncs"
grep -q $'\e\[33m' "$WORK/out" && grep -q '==> Log in to atuin' "$WORK/out" && ! grep -q $'\e\[31m\r\?$\|\e\[31m==> Log in' "$WORK/out" &&
  ok "terminal: what to do is yellow, not red" || bad "terminal: what to do is yellow, not red ($(cat -v "$WORK/out" | grep -m1 'Log in'))"
reset 2; on_tty; eq "$? $(count login) $(count sync)" "0 2 1" "terminal: a failed try asks again"
reset 9; on_tty; eq "$(( $? != 0 )) $(count login) $(count sync)" "1 3 0" "terminal: gives up after 3"

reset; touch "$WORK/badsync"; on_tty; eq "$(( $? != 0 )) $(count logout)" "1 1" "failed sync: an error, logged out again"
login check; eq $? 1 "failed sync: check asks again"

reset; (sleep 2; touch "$WORK/in") & ATUIN_LOGIN_WAIT=20 login install
eq "$? $(count login) $(count sync)" "0 0 1" "no terminal: waits for a login made elsewhere"
! grep -q $'\e\[' "$WORK/out" && ok "no terminal: no colour codes" || bad "no terminal: no colour codes ($(cat -v "$WORK/out" | head -2))"
wait
reset; ATUIN_LOGIN_WAIT=0 login install; eq "$(( $? != 0 )) $(count sync)" "1 0" "no terminal: gives up after the wait"

reset; touch "$WORK/in"; on_tty; eq "$? $(count login)" "0 0" "already logged in: asks nothing"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
