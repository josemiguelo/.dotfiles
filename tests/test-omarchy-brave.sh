#!/usr/bin/env bash
# Tests loadouts/private_dot_config/.omarchy/.loadout/omarchy-brave.ts: the
# extensions on brave-flags.conf's --load-extension line that aren't
# Omarchy's survive `omarchy install browser brave`, which copies Omarchy's
# flags over the file. Each case runs the script with XDG_CONFIG_HOME at a
# fixture and, first on PATH, a fake `omarchy` doing what the real installer
# does to the file (cp -f of Omarchy's flags) and a fake `pacman` saying
# brave-bin is installed. Its ready check also reads
# /etc/brave/policies/managed, which can't be faked: without it (Brave never
# set up by Omarchy here) the cases are skipped. Run: tests/test-omarchy-brave.sh

set -u
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SCRIPT="$REPO/loadouts/private_dot_config/.omarchy/.loadout/omarchy-brave.ts"
BUN="$(bun -e 'console.log(process.execPath)')" || { echo "bun not found"; exit 1; }
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }
not_contains() { [[ "$1" != *"$2"* ]] && ok "$3" || bad "$3 (expected NOT to contain [$2], got [$1])"; }

if [[ ! -d /etc/brave/policies/managed ]]; then
  echo "  skip - no /etc/brave/policies/managed (Omarchy's Brave isn't set up here)"
  exit 0
fi

O=/usr/share/omarchy/default/chromium/extensions
mkdir -p "$WORK/bin" "$WORK/config"
# Omarchy's chromium-flags.conf, as it ships.
cat >"$WORK/omarchy-flags.conf" <<EOF
--ozone-platform=wayland
--load-extension=$O/copy-url,$O/yt-dlp
--no-default-browser-check
EOF
cat >"$WORK/bin/omarchy" <<EOF
#!/bin/sh
cp -f "$WORK/omarchy-flags.conf" "\$XDG_CONFIG_HOME/brave-flags.conf"
EOF
printf '#!/bin/sh\nexit 0\n' >"$WORK/bin/pacman"
chmod +x "$WORK/bin/omarchy" "$WORK/bin/pacman"
FLAGS="$WORK/config/brave-flags.conf"

# install_with <flags before, or - for none>: runs the script, prints its exit code.
install_with() {
  rm -f "$FLAGS"
  [[ "$1" == - ]] || printf '%s' "$1" >"$FLAGS"
  (cd "$REPO" && PATH="$WORK/bin:$PATH" XDG_CONFIG_HOME="$WORK/config" "$BUN" "$SCRIPT" install >/dev/null 2>&1)
  echo $?
}
last_line() { grep '^--load-extension=' "$FLAGS" | tail -n 1; }
lines() { grep -c '^--load-extension=' "$FLAGS"; }

echo "no flags file before"
eq "$(install_with -)" 0 "installs"
eq "$(last_line)" "--load-extension=$O/copy-url,$O/yt-dlp" "Omarchy's line as it ships"

echo "Intentional's and split view's extensions on the line"
eq "$(install_with "--ozone-platform=wayland
--load-extension=$O/copy-url,/home/u/.local/share/intentional/extension,/home/u/.config/surfingkeys/split-view
")" 0 "installs"
eq "$(last_line)" "--load-extension=$O/copy-url,$O/yt-dlp,/home/u/.local/share/intentional/extension,/home/u/.config/surfingkeys/split-view" "carried after Omarchy's, in order"
eq "$(lines)" 1 "one --load-extension line"
eq "$(tail -n 1 "$FLAGS")" "--no-default-browser-check" "the rest of Omarchy's file as it was"

echo "only the last --load-extension line counts, as in Chromium"
eq "$(install_with "--load-extension=/stale/one
--load-extension=/x/ext
")" 0 "installs"
eq "$(last_line)" "--load-extension=$O/copy-url,$O/yt-dlp,/x/ext" "the last line's extension carried"
not_contains "$(cat "$FLAGS")" /stale/one "an earlier line's isn't"

echo "an Omarchy extension Omarchy stopped shipping"
eq "$(install_with "--load-extension=$O/old-one,/x/ext")" 0 "installs"
not_contains "$(cat "$FLAGS")" "$O/old-one" "isn't carried back"

echo
echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
