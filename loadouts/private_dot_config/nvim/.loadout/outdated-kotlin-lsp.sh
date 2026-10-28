#!/bin/sh
# kotlin-lsp's update check (install-kotlin-lsp.sh): is ~/.local/share/
# kotlin-lsp/current behind the latest release? Its builds expire a few
# weeks after release, so staying behind ends with a server that won't start.
#
#   outdated-kotlin-lsp.sh          print the latest version when behind, else nothing
#   outdated-kotlin-lsp.sh update   install the latest release
#   outdated-kotlin-lsp.sh version  the installed version (loadout's version check)
#
# Silent when it isn't installed or the network is down.
set -eu
here=$(dirname "$0")

current() {
  basename "$(readlink "$HOME/.local/share/kotlin-lsp/current" 2>/dev/null)" 2>/dev/null
}

latest() {
  url=$(curl -fsSLo /dev/null -w '%{url_effective}' https://github.com/Kotlin/kotlin-lsp/releases/latest 2>/dev/null) || return 1
  echo "${url##*/v}"
}

case ${1:-} in
update) exec sh "$here/install-kotlin-lsp.sh" ;;
version)
  cur=$(current)
  [ -n "$cur" ] || exit 1
  echo "$cur"
  ;;
"")
  cur=$(current) || exit 0
  [ -n "$cur" ] || exit 0
  new=$(latest) || exit 0
  [ -n "$new" ] && [ "$new" != "$cur" ] && echo "$new"
  exit 0
  ;;
*)
  echo "usage: $0 [update|version]" >&2
  exit 2
  ;;
esac
