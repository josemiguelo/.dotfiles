#!/usr/bin/env bash
# Tests loadouts/ssh/.loadout/github-ssh-key.ts with fakes on PATH, the one
# script that deletes keys from the GitHub account: only the keys titled with
# this machine's name that aren't its key go; every other key stays. The fake
# gh keeps the account's keys in $WORK/keys (id<TAB>title<TAB>key), the fake
# ssh "authenticates" a key whose public half is there, and the fake ssh-add
# keeps the agent's keys in $WORK/agent. Nothing reaches GitHub or a real
# agent. Run: tests/test-github-ssh-key.sh
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$REPO/loadouts/ssh/.loadout/github-ssh-key.ts"
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT
mkdir -p "$WORK/bin" "$WORK/home/.ssh"

cat > "$WORK/bin/gh" <<'F'
#!/usr/bin/env bash
W="$(cd "$(dirname "$0")/.." && pwd)"
echo "gh $*" >> "$W/log"
case "$1 $2" in
"auth status") [[ " $* " == *" 2>&1 "* ]] || true; echo "Logged in to github.com; Token scopes: 'admin:public_key', 'repo'" ;;
"api user/keys")
  if [[ "$*" == *'.id'* ]]; then cat "$W/keys"; else cut -f3 "$W/keys"; fi ;;
"ssh-key delete") grep -v "^$3	" "$W/keys" > "$W/keys.new"; mv "$W/keys.new" "$W/keys" ;;
"ssh-key add")
  id=$(( $(cut -f1 "$W/keys" | sort -n | tail -1) + 1 ))
  printf '%s\t%s\t%s\n' "$id" "$5" "$(cut -d' ' -f2 "$3")" >> "$W/keys" ;;
"config get") cat "$W/protocol" 2>/dev/null ;;
"config set") echo "$6" > "$W/protocol" ;;
*) echo "fake gh: unexpected $*" >&2; exit 99 ;;
esac
F
cat > "$WORK/bin/ssh" <<'F'
#!/usr/bin/env bash
W="$(cd "$(dirname "$0")/.." && pwd)"
while [[ $# -gt 0 && $1 != -i ]]; do shift; done
key=$(cut -d' ' -f2 "$2.pub")
if cut -f3 "$W/keys" | grep -qxF "$key"; then echo "Hi! You've successfully authenticated"; else echo "Permission denied (publickey)."; exit 255; fi
F
cat > "$WORK/bin/ssh-add" <<'F'
#!/usr/bin/env bash
W="$(cd "$(dirname "$0")/.." && pwd)"
case "${1:-}" in
-l) exit 0 ;;
-L) cat "$W/agent" 2>/dev/null ;;
*) cut -d' ' -f2 "$1.pub" >> "$W/agent" ;;
esac
F
chmod +x "$WORK/bin/"*

export HOME="$WORK/home" LOADOUT_REPO="$REPO" LOADOUT_MACHINE=box MISE_DATA_DIR="$WORK/mise"
export PATH="$WORK/bin:$PATH"
echo "ssh-ed25519 MINE box" > "$HOME/.ssh/id_ed25519.pub"
: > "$HOME/.ssh/id_ed25519"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
run() { loadout bun "$REPO/tests/run-module.ts" "$MODULE" "$1" '{"key":"id_ed25519"}' > "$WORK/out" 2>&1; }
account() { cut -f2,3 "$WORK/keys" | tr '\t' ':' | sort | tr '\n' ' '; }
reset() { printf '%b' "$1" > "$WORK/keys"; rm -f "$WORK/agent" "$WORK/protocol" "$WORK/log"; touch "$WORK/log"; [[ -z ${2:-} ]] || echo "$2" > "$WORK/protocol"; }

echo "a new machine: its old keys go, the others stay, its key is added"
reset '1\tbox\tOLD1\n2\tlaptop\tLAPTOP\n3\tbox\tOLD2\n4\tbox-2\tOTHER\n' https
run check; eq $? 1 "check: not on GitHub"
run install; eq $? 0 "install succeeds ($(tail -1 "$WORK/out"))"
eq "$(account)" "box-2:OTHER box:MINE laptop:LAPTOP " "only box's previous keys deleted; box-2's and laptop's kept"
eq "$(cat "$WORK/protocol")" ssh "gh's git protocol is ssh"
eq "$(grep -c 'ssh-key delete' "$WORK/log")" 2 "two deletes, no more"
run check; eq $? 0 "check: done"

echo "already authenticating: nothing deleted or added"
reset '1\tbox\tMINE\n2\tbox\tOLD\n' ssh
run install; eq $? 0 "install succeeds"
eq "$(account)" "box:MINE box:OLD " "the account is left as it is"
eq "$(grep -c 'ssh-key' "$WORK/log")" 0 "no key call"

echo "authenticating, gh on https: only the protocol changes"
reset '1\tbox\tMINE\n' https
run check; eq $? 1 "check: the protocol isn't ssh"
run install; eq $? 0 "install succeeds"
eq "$(cat "$WORK/protocol")" ssh "the protocol is ssh now"

echo "its own key under its title is never deleted"
reset '7\tbox\tMINE\n8\tbox\tOLD\n' ssh
# GitHub refuses it this time (a key just added can take a moment): install runs the delete pass.
mv "$WORK/bin/ssh" "$WORK/bin/ssh.real"
printf '%s\n' '#!/usr/bin/env bash' 'W="$(cd "$(dirname "$0")/.." && pwd)"' \
  '[[ -e $W/refused ]] && exec "$W/bin/ssh.real" "$@"' 'touch "$W/refused"; echo "Permission denied (publickey)."; exit 255' > "$WORK/bin/ssh"
chmod +x "$WORK/bin/ssh"
run install; eq $? 0 "install succeeds ($(tail -1 "$WORK/out"))"
eq "$(account)" "box:MINE " "the previous key goes, its own stays"
eq "$(grep -c 'ssh-key add' "$WORK/log")" 0 "and isn't added twice"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
