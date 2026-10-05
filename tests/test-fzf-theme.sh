#!/usr/bin/env bash
# Tests configs/private_dot_config/fzf/theme.sh: which palette it picks for
# each place appearance-is-dark can be. The bug this guards: kitty's overlay has
# no ~/.local/bin on PATH, so the lookup missed the script and the picker
# silently used the dark palette. Each case runs in a fresh bash with a
# throwaway HOME and a PATH that holds only what the case needs. Run:
# tests/test-fzf-theme.sh
set -u

SCRIPT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/configs/private_dot_config/fzf/theme.sh"
WORK="$(mktemp -d)"
trap 'rm -rf -- "${WORK:?}"' EXIT

# Palette markers: bg+ is the one color that differs between the two palettes.
DARK_BGPLUS="#2e3c64"
LIGHT_BGPLUS="#b7c1e3"

# fake_appearance DIR EXIT_CODE: writes DIR/appearance-is-dark, exiting with
# EXIT_CODE (0 = dark, 1 = light, as the real script does).
fake_appearance() {
  mkdir -p "$1"
  printf '#!/bin/sh\nexit %s\n' "$2" > "$1/appearance-is-dark"
  chmod +x "$1/appearance-is-dark"
}

# palette HOME PATH: prints the bg+ color theme.sh exports, from a fresh bash.
palette() {
  env -i HOME="$1" PATH="$2" bash -c 'source "$1"; printf "%s" "$FZF_DEFAULT_OPTS"' _ "$SCRIPT" \
    | grep -o 'bg+:#[0-9a-f]*' | cut -d: -f2
}

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

SYSTEM_PATH="/usr/bin:/bin"

# The kitty overlay case: the script lives in ~/.local/bin but PATH lacks it.
home="$WORK/light-home"
fake_appearance "$home/.local/bin" 1
eq "$(palette "$home" "$SYSTEM_PATH")" "$LIGHT_BGPLUS" "light mode, ~/.local/bin off PATH: light palette"

home="$WORK/dark-home"
fake_appearance "$home/.local/bin" 0
eq "$(palette "$home" "$SYSTEM_PATH")" "$DARK_BGPLUS" "dark mode, ~/.local/bin off PATH: dark palette"

# A copy on PATH wins over the one in ~/.local/bin (chztry previews put theirs
# first on PATH).
home="$WORK/path-wins-home"
fake_appearance "$home/.local/bin" 0
fake_appearance "$WORK/preview-bin" 1
eq "$(palette "$home" "$WORK/preview-bin:$SYSTEM_PATH")" "$LIGHT_BGPLUS" "appearance-is-dark on PATH is used before ~/.local/bin"

# No script anywhere: the storm (dark) palette, as the comment in theme.sh says.
home="$WORK/none-home"
mkdir -p "$home"
eq "$(palette "$home" "$SYSTEM_PATH")" "$DARK_BGPLUS" "no appearance-is-dark anywhere: dark palette"

echo "$pass passed, $fail failed"
[[ $fail -eq 0 ]]
