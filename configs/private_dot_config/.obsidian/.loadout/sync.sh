#!/bin/sh
# An Obsidian Sync vault in a local folder through Obsidian Headless (`ob`,
# from mise), set up as the machine names it:
# `run(Obsidian.sync, "<vault>", "<path>", "<mode>")`. The mode is
# `bidirectional`, `pull-only` or `mirror-remote`; the rest stays ob's
# defaults (merge on conflict; images, audio, PDFs and videos besides notes;
# no app settings). Logging in, and the vault's encryption password if it has
# one, are asked for in the terminal the first time; the first sync follows.
# usage: sync.sh [check] <vault> <path> <mode>
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
[ "$#" -eq 3 ] || { echo "usage: $0 [check] <vault> <path> <mode>" >&2; exit 2; }
vault=$1
dir=$(eval echo "$2") # a ~ in the machine's path
mode=$3
command -v ob >/dev/null 2>&1 || { echo "ob not found (mise's npm:obsidian-headless)" >&2; exit 1; }

# The vault's settings as `ob sync-config` prints them, or nothing when that
# folder isn't set up.
config() { ob sync-config --path "$dir" 2>/dev/null || true; }
configured() {
  c=$(config)
  printf '%s\n' "$c" | grep -q "^ *Vault: $vault (" &&
    printf '%s\n' "$c" | grep -q "^ *Sync mode: $mode\$"
}
logged_in() { ob login </dev/null 2>/dev/null | grep -q '^Logged in as'; }

if [ "$MODE" = check ]; then
  logged_in && configured
  exit $?
fi

logged_in || ob login
mkdir -p "$dir"
config | grep -q "^ *Vault: $vault (" || ob sync-setup --vault "$vault" --path "$dir"
ob sync-config --path "$dir" --mode "$mode" >/dev/null
ob sync --path "$dir"
