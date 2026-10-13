#!/bin/sh
# Custom `loadout outdated` oracle for Omarchy shell plugins installed from
# git (~/.config/omarchy/plugins/<id>, a clone each): a row per plugin whose
# clone is behind its remote's HEAD, named by the plugin id. Silent when no
# plugin is installed.
#
# `update <id>` (loadout calls it per row) is Omarchy's own `omarchy plugin
# update <id> --yes`: it fast-forwards, validates (rolling back a failure)
# and reloads the shell's plugins.
#
# A clone with commits of its own (a local patch on a branch) or uncommitted
# changes can't be fast-forwarded: its row says so ("diverged: …"), and
# `update` refuses it, naming what's in the way, instead of letting
# omarchy-plugin-update fail on it.
set -eu

PLUGINS=$HOME/.config/omarchy/plugins
GCB="$LOADOUT_REPO/maintenance/lib/git-clones-behind.sh"
. "$LOADOUT_REPO/maintenance/omarchy/lib/plugin-update-hint.sh"
# The folder is named by the plugin id.
export GCB_NAME='basename "$dir"'

if [ "${1:-}" = "update" ]; then
  id=${2:?usage: omarchy-plugins.sh update <id>}
  [ -d "$PLUGINS/$id/.git" ] || { echo "no git-managed plugin '$id'" >&2; exit 1; }
  git -C "$PLUGINS/$id" fetch --quiet origin HEAD
  why=$(plugin_diverged "$PLUGINS/$id")
  [ -z "$why" ] || { echo "$id has $why: \`omarchy plugin update\` can't fast-forward $PLUGINS/$id; bring it up to date by hand" >&2; exit 1; }
  exec omarchy plugin update "$id" --yes
fi

dirs=""
for dir in "$PLUGINS"/*/; do
  [ -d "$dir.git" ] && dirs="$dirs ${dir%/}"
done
[ -n "$dirs" ] || exit 0
# git-clones-behind leaves each clone's FETCH_HEAD at its remote's HEAD,
# which plugin_diverged compares against.
# shellcheck disable=SC2086
rows=$(sh "$GCB" $dirs)
[ -n "$rows" ] || exit 0
printf '%s\n' "$rows" | while read -r id rest; do
  why=$(plugin_diverged "$PLUGINS/$id")
  printf '%s %s%s\n' "$id" "$rest" "${why:+ diverged: $why, update by hand}"
done
