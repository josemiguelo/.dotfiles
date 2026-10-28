#!/bin/sh
# Omarchy's default coding agent (what its agent keybinding and menu open),
# set the native way: `omarchy default agent <name>`. The agent itself must
# already be installed — on Omarchy, mise installs it from the dotfiles'
# config — so Omarchy doesn't open its install terminal instead.
#
# Heads-up: setting it the native way also LAUNCHES the agent in a new
# terminal (the command ends in `omarchy-agent`), the same as picking one in
# Omarchy's menu. The check keeps that to the first run, and the run doesn't
# wait for that window.
# usage: omarchy-default-agent.sh <agent>
set -eu
AGENT=${1:?usage: omarchy-default-agent.sh <agent>}
# The global config only: `omarchy default agent` runs `mise where`/`mise use
# -g`, and from the repo's cwd mise would also find the dotfiles' copy of its
# config in a parent and stop to ask whether to trust it.
cd "$HOME"
command -v "$AGENT" >/dev/null 2>&1 || { echo "$AGENT is not installed" >&2; exit 1; }
# Detached: the launch only returns when that terminal closes, and its exit
# status is the agent's, not the setting's. The setting is judged by reading
# it back once it's saved (it is, right before the launch).
# It also runs `mise use -g <agent>` first, writing the agent into the
# dotfiles' config.toml; conf.d/omarchy.toml already lists it, so config.toml
# goes back to what it was once the setting is saved.
CONF=$HOME/.config/mise/config.toml
saved=$(mktemp)
trap 'rm -f "$saved"' EXIT
cp -p "$CONF" "$saved"
setsid omarchy default agent "$AGENT" </dev/null >/dev/null 2>&1 &
tries=0
until [ "$(omarchy default agent)" = "$AGENT" ]; do
  tries=$((tries + 1))
  [ "$tries" -lt 60 ] || { cp -p "$saved" "$CONF"; echo "the default agent is still not $AGENT" >&2; exit 1; }
  sleep 1
done
cp -p "$saved" "$CONF"
