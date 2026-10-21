#!/bin/sh
# Omarchy sets up every coding agent it offers, used or not. This removes
# what it set up for the agents the machine doesn't name:
#
# - the launcher it writes into ~/.local/bin (install/user/mise.sh via
#   omarchy-mise-install): a script that runs `mise use -g <tool>` on first
#   use. Like omarchy-remove-preinstalls decides what is Omarchy's: a regular
#   file (not a symlink — Cursor's own installer links cursor-agent) carrying
#   the `mise use -g` line. Anything else at those paths is left alone (since
#   Omarchy 4.0.5, hermes is Hermes Desktop's own command, not a launcher).
# - the config folder it seeds into ~/.config from $OMARCHY_PATH/config
#   (only opencode has one): removed only while the agent isn't installed
#   (on PATH other than as that launcher) and every file in it is still
#   Omarchy's copy, so a config of your own stays. Left there, it makes
#   workmux setup take the agent as installed and fail on `<agent> --version`.
#
# Omarchy re-provisioning (or omarchy-reinstall-configs) writes them again, so
# the check catches a return.
# usage: omarchy-agents-prune.sh [check] <agent-to-keep>...
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
BIN=$HOME/.local/bin
CONFIG=${XDG_CONFIG_HOME:-$HOME/.config}
OMARCHY_CONFIG=${OMARCHY_PATH:-/usr/share/omarchy}/config

# Agents whose config folder Omarchy seeds, by the folder's name.
AGENT_CONFIGS="opencode"

kept() {
  for keep in $KEEP; do [ "$keep" = "$1" ] && return 0; done
  return 1
}

omarchy_launcher() {
  [ -f "$1" ] && [ ! -L "$1" ] && grep -q '^mise use -g ' "$1"
}

# On PATH as itself, not as Omarchy's launcher for it.
installed() {
  cmd=$(command -v "$1" 2>/dev/null) || return 1
  ! omarchy_launcher "$cmd"
}

# Every file in ~/.config/<agent> is the same as in Omarchy's copy.
omarchy_config() {
  [ -d "$CONFIG/$1" ] && [ -d "$OMARCHY_CONFIG/$1" ] || return 1
  (cd "$CONFIG/$1" && find . ! -type d) | while read -r f; do
    cmp -s "$CONFIG/$1/$f" "$OMARCHY_CONFIG/$1/$f" || exit 1
  done
}

extra_launchers() {
  for f in "$BIN"/*; do
    kept "$(basename "$f")" && continue
    omarchy_launcher "$f" && basename "$f"
  done
  return 0
}

extra_configs() {
  for name in $AGENT_CONFIGS; do
    kept "$name" && continue
    installed "$name" && continue
    omarchy_config "$name" && echo "$CONFIG/$name"
  done
  return 0
}

extra() {
  for name in $(extra_launchers); do echo "$BIN/$name"; done
  extra_configs
}

KEEP="$*"
case "$MODE" in
check)
  [ -z "$(extra)" ]
  ;;
install)
  for path in $(extra); do
    rm -rf "$path"
    echo "removed $path"
  done
  [ -z "$(extra)" ] || { echo "Omarchy agent files still present: $(extra | tr '\n' ' ')" >&2; exit 1; }
  ;;
esac
