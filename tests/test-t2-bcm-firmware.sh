#!/usr/bin/env bash
# Tests loadouts/t2/.loadout/bcm-firmware.ts with fakes on PATH and its system
# paths under T2_BCM_FIRMWARE_ROOT: which source it picks (the macOS volume on
# the internal disk, else the fallback package from 1Password), that check
# never asks 1Password, and that a 1Password document with the wrong SHA-256
# is refused before anything is removed or installed. The fake pacman keeps
# its packages in $WORK/pkgs (name<TAB>explicit|dep), the fake fetcher writes
# its state file, and every command is logged to $WORK/log. Nothing touches
# the system. (The fallback's success needs the real package, whose SHA-256
# the script checks: not something a test can stand in for.)
# Run: tests/test-t2-bcm-firmware.sh
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MODULE="$REPO/loadouts/t2/.loadout/bcm-firmware.ts"
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT
mkdir -p "$WORK/bin" "$WORK/root"
export T2_BCM_FIRMWARE_ROOT="$WORK/root" LOADOUT_REPO="$REPO" OP_UNLOCK_WAIT=0
STATE="$WORK/root/var/lib/apple-bcm-firmware-fetcher/installed-files"

fake() { printf '#!/usr/bin/env bash\nW=%q\necho "%s $*" >> "$W/log"\n%s\n' "$WORK" "$1" "$2" > "$WORK/bin/$1"; chmod +x "$WORK/bin/$1"; }
fake sudo 'exec "$@"'
fake lsblk 'cat "$W/lsblk"'
fake modprobe 'exit 0'
fake op 'case "$1 $2" in "vault list") exit 0 ;; "document get") out=${@: -1}; echo "not the package" > "$out" ;; esac'
fake omarchy-pkg-add 'printf "%s\tdep\n" "$1" >> "$W/pkgs"'
fake apple-bcm-firmware-fetcher 'mkdir -p "$(dirname "$T2_BCM_FIRMWARE_ROOT/var/lib/apple-bcm-firmware-fetcher/installed-files")"; echo /lib/firmware/brcm/x > "$T2_BCM_FIRMWARE_ROOT/var/lib/apple-bcm-firmware-fetcher/installed-files"'
fake pacman '
pkg=${@: -1}
has() { cut -f1 "$W/pkgs" | grep -qx "$1"; }
case "$1" in
-Q|-Qk) has "$pkg" ;;
-Qqe) grep -qx "$pkg	explicit" "$W/pkgs" ;;
-R) grep -v "^$pkg	" "$W/pkgs" > "$W/pkgs.new"; mv "$W/pkgs.new" "$W/pkgs" ;;
-U) printf "apple-bcm-firmware\texplicit\n" >> "$W/pkgs" ;;
-D) sed -i "s/^$pkg\tdep$/$pkg\texplicit/" "$W/pkgs" ;;
*) echo "fake pacman: unexpected $*" >&2; exit 99 ;;
esac'
export PATH="$WORK/bin:$PATH"

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
run() { loadout bun "$REPO/tests/run-module.ts" "$MODULE" "$1" > "$WORK/out" 2>&1; }
reset() { printf '%b' "$1" > "$WORK/pkgs"; printf '%b' "$2" > "$WORK/lsblk"; rm -rf -- "${WORK:?}/root"; mkdir -p "$WORK/root"; : > "$WORK/log"; }
pkgs() { sort "$WORK/pkgs" | tr '\t\n' ': '; }
called() { grep -c "^$1" "$WORK/log"; }

echo "check"
reset 'apple-bcm-firmware-fetcher\texplicit\n' ''
mkdir -p "$(dirname "$STATE")" && echo x > "$STATE"
run check; eq $? 0 "the fetcher, explicit, with its firmware fetched: done"
reset 'apple-bcm-firmware-fetcher\tdep\n' ''
mkdir -p "$(dirname "$STATE")" && echo x > "$STATE"
run check; eq $? 1 "the fetcher as a dependency (omarchy-update would remove it): not done"
reset '' ''
run check; eq $? 1 "nothing: not done"
eq "$(called op)" 0 "check never asks 1Password"

echo "a macOS volume on the internal disk: the fetcher"
reset 'apple-bcm-firmware\texplicit\n' '/dev/nvme0n1p1 vfat\n/dev/nvme0n1p2 apfs\n/dev/nvme0n1p3 ext4\n'
run install; eq $? 0 "install succeeds ($(tail -1 "$WORK/out"))"
eq "$(pkgs)" "apple-bcm-firmware-fetcher:explicit " "the fallback package removed, the fetcher installed explicitly"
[[ -s $STATE ]] && ok "the fetcher fetched" || bad "the fetcher fetched"
eq "$(called op)" 0 "1Password never asked"
eq "$(called 'modprobe brcmfmac')" 1 "the Wi-Fi driver reloads"
run check; eq $? 0 "check: done"

echo "APFS on another disk isn't the macOS volume"
reset '' '/dev/sda1 apfs\n/dev/nvme0n1p3 ext4\n'
run install; eq $? 1 "install goes to the fallback (and fails here: the document isn't the package)"
eq "$(called 'apple-bcm-firmware-fetcher')" 0 "the fetcher isn't run"
eq "$(called 'op document get')" 1 "the package is asked of 1Password"

echo "no macOS volume, a wrong document in 1Password: refused before anything changes"
reset 'apple-bcm-firmware-fetcher\texplicit\n' '/dev/nvme0n1p3 ext4\n'
run install; eq $? 1 "install fails"
grep -q "doesn't match its SHA256" "$WORK/out" && ok "it says the document doesn't match" || bad "it says the document doesn't match ($(tail -2 "$WORK/out"))"
eq "$(pkgs)" "apple-bcm-firmware-fetcher:explicit " "the fetcher isn't removed"
eq "$(called 'pacman -U')" 0 "nothing is installed"
[[ ! -e $WORK/root/var/lib/t2-bcm-firmware ]] && ok "no copy is kept" || bad "no copy is kept"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
