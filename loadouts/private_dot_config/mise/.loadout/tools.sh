#!/bin/sh
# mise tools: every version ~/.config/mise/config.toml pins (the file comes
# from the chezmoi dotfiles; the mise-tools oracle moves its pins) is
# installed. No plugin step: mise resolves every tool from its own
# registry. Lazy tools (Omarchy 4.5's agents, /etc/mise/conf.d) install on
# first use and `mise install` skips them, so they count as present.
# Modes: `check` / `install` (default).
set -eu
command -v mise >/dev/null 2>&1 || { echo "mise not found" >&2; exit 1; }
# The global config only: from the repo's cwd mise would also look for
# project configs in its parents.
cd "$HOME"

case "${1:-install}" in
check)
  # Captured first: a mise error (an untrusted or broken config) prints
  # nothing, which would read as "nothing missing". Its message stays on stderr.
  out=$(mise ls --missing) || { echo "mise ls --missing failed" >&2; exit 1; }
  missing=$(printf '%s\n' "$out" | awk 'NF && !/\(lazy\)/ { print $1 "@" $2 }')
  [ -z "$missing" ] && exit 0
  for m in $missing; do echo "missing: $m"; done
  exit 1
  ;;
install)
  # Python 2.x builds from source, and its ssl module only against OpenSSL
  # 1.x: where openssl-1.1 sits beside the system's (Arch, the AUR's
  # package), those versions build first, pointed at it. Only them: the
  # flags would also reach any other tool mise compiles.
  ssl11=/usr/include/openssl-1.1
  if [ -d "$ssl11" ]; then
    out=$(mise ls --missing python) || { echo "mise ls --missing failed" >&2; exit 1; }
    for v in $(printf '%s\n' "$out" | awk '$2 ~ /^2\./ { print $2 }'); do
      CPPFLAGS="-I$ssl11" LDFLAGS="-L/usr/lib/openssl-1.1" mise install "python@$v"
    done
  fi
  mise install
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
