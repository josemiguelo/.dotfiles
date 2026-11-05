#!/bin/sh
# Hands loadout's check/install to the Intentional checkout's own installer
# (desktop/install.sh), which builds the Kotlin/Native daemon with Gradle and
# installs it with its Brave extension. INTENTIONAL_REPO overrides where the
# checkout is. Modes: `check` / `install` (default).
set -eu

repo="${INTENTIONAL_REPO:-$HOME/Repos/gh/josemiguelo/intentional/all_worktrees/main}"
if [ ! -x "$repo/desktop/install.sh" ]; then
  [ "${1:-install}" = check ] && exit 1
  echo "no Intentional checkout at $repo: clone github.com/josemiguelo/intentional (or set INTENTIONAL_REPO)" >&2
  exit 1
fi
exec "$repo/desktop/install.sh" "$@"
