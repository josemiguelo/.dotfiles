#!/bin/sh
# workmux's status-tracking hooks and bundled skills, for every agent whose
# config folder is here: what `workmux setup --hooks --skills` writes.
# workmux can't report it, so check looks for the files it writes, the way it
# finds agents (by config folder), and for a stamp of the workmux version it
# last ran with: an upgrade can change the hooks or skills, so it reruns once.
# A new agent or skill in workmux needs a line here.
# setup asks before each part and only on a terminal, so install runs it in
# one (script) and answers yes.
# Modes: `check` / `install` (default).
set -eu

SKILLS="merge rebase worktree coordinator open-pr workmux"
STAMP=${XDG_STATE_HOME:-$HOME/.local/state}/workmux-setup/version

CLAUDE=${CLAUDE_CONFIG_DIR:-$HOME/.claude}
PI=$HOME/.pi/agent
CODEX=$HOME/.codex
COPILOT=${COPILOT_CONFIG_DIR:-$HOME/.copilot}
OPENCODE=${OPENCODE_CONFIG_DIR:-${XDG_CONFIG_HOME:-$HOME/.config}/opencode}

skills() {
  for skill in $SKILLS; do
    [ -f "$1/$skill/SKILL.md" ] || { echo "missing skill: $1/$skill"; return 1; }
  done
}

has() { [ -f "$2" ] && grep -q "$1" "$2"; }

# Prints what's missing; fails when anything is.
missing() {
  ok=0
  if [ -d "$CLAUDE" ]; then
    has 'workmux set-window-status' "$CLAUDE/settings.json" || { echo "missing hooks: $CLAUDE/settings.json"; ok=1; }
    skills "$CLAUDE/skills" || ok=1
  fi
  if [ -d "$PI" ]; then
    [ -f "$PI/extensions/workmux-status.ts" ] || { echo "missing hooks: $PI/extensions/workmux-status.ts"; ok=1; }
    skills "$PI/skills" || ok=1
  fi
  if [ -d "$CODEX" ]; then
    has 'workmux set-window-status' "$CODEX/hooks.json" || { echo "missing hooks: $CODEX/hooks.json"; ok=1; }
  fi
  if [ -d "$COPILOT" ]; then
    [ -f "$COPILOT/hooks/workmux-status.json" ] || { echo "missing hooks: $COPILOT/hooks/workmux-status.json"; ok=1; }
  fi
  if [ -d "$OPENCODE" ]; then
    ls "$OPENCODE"/plugin/workmux-status* "$OPENCODE"/plugins/workmux-status* >/dev/null 2>&1 \
      || { echo "missing hooks: $OPENCODE/plugin/workmux-status.ts"; ok=1; }
    skills "$OPENCODE/skills" || ok=1
  fi
  version=$(workmux --version)
  [ "$(cat "$STAMP" 2>/dev/null)" = "$version" ] || { echo "last set up by another workmux than $version"; ok=1; }
  return $ok
}

in_terminal() {
  if [ "$(uname -s)" = "Darwin" ]; then
    script -q /dev/null "$@"
  else
    script -q -e -c "$*" /dev/null
  fi
}

case "${1:-install}" in
  check)
    missing >/dev/null
    ;;
  install)
    yes | head -n 10 | in_terminal workmux setup --hooks --skills
    mkdir -p "$(dirname "$STAMP")"
    workmux --version >"$STAMP"
    missing >&2 || { echo "workmux setup left these out" >&2; exit 1; }
    ;;
esac
