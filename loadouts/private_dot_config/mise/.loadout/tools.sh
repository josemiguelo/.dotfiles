#!/bin/sh
# mise tools: every version ~/.config/mise/config.toml pins (the file comes
# from the chezmoi dotfiles; the mise-tools oracle moves its pins) is
# installed. No plugin step: mise resolves every tool from its own
# registry. Lazy tools (Omarchy 4.5's agents, /etc/mise/conf.d) install on
# first use and `mise install` skips them, so they count as present.
#
# Named tools (`tools.sh node python`) narrow it to each one's default
# version, the first config.toml lists (what a shell gets): the core of a
# setup, with mise-tools-later (no names) installing the rest afterwards.
# One config.toml either way: mise hides a tool's versions in a second file
# whenever config.toml lists that tool too, so the split is in what's
# installed, not in the files. Names, not versions, so a pin the oracle
# moves needs no change here.
# usage: tools.sh [check] [tool...]
set -eu
command -v mise >/dev/null 2>&1 || { echo "mise not found" >&2; exit 1; }
# The global config only: from the repo's cwd mise would also look for
# project configs in its parents.
cd "$HOME"

MODE=install
case "${1:-}" in check | install) MODE=$1; shift ;; esac

# The default version of each named tool that isn't installed, as tool@version.
missing_defaults() {
  for tool in "$@"; do
    v=$(mise current "$tool" 2>/dev/null | awk '{ print $1 }')
    [ -n "$v" ] || { echo "$tool isn't in mise's config" >&2; return 1; }
    mise where "$tool@$v" >/dev/null 2>&1 || echo "$tool@$v"
  done
}

if [ $# -gt 0 ]; then
  case "$MODE" in
  check)
    missing=$(missing_defaults "$@") || exit 1
    [ -z "$missing" ] && exit 0
    for m in $missing; do echo "missing: $m"; done
    exit 1
    ;;
  install)
    missing=$(missing_defaults "$@") || exit 1
    # shellcheck disable=SC2086 # one tool@version each
    [ -z "$missing" ] || mise install $missing
    missing=$(missing_defaults "$@") || exit 1
    [ -z "$missing" ] || { echo "still missing after mise install: $missing" >&2; exit 1; }
    ;;
  esac
  exit 0
fi

case "$MODE" in
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
*) echo "usage: $0 [check] [tool...]" >&2; exit 2 ;;
esac
