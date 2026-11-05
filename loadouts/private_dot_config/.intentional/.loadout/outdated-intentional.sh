#!/bin/sh
# Intentional's update check (intentional.sh): is the installed desktop guard
# behind the latest GitHub release?
#
#   outdated-intentional.sh          print the latest version when behind, else nothing
#   outdated-intentional.sh update   install the latest release
#
# Silent when it isn't installed or the network is down.
set -eu
here=$(dirname "$0")

current() {
  intentional --version 2>/dev/null | cut -d' ' -f2
}

latest() {
  url=$(curl -fsSLo /dev/null -w '%{url_effective}' https://github.com/josemiguelo/intentional/releases/latest 2>/dev/null) || return 1
  echo "${url##*/v}"
}

case ${1:-} in
update) exec sh "$here/intentional.sh" install ;;
"")
  cur=$(current) || exit 0
  [ -n "$cur" ] || exit 0
  new=$(latest) || exit 0
  [ -n "$new" ] && [ "$new" != "$cur" ] && echo "$new"
  exit 0
  ;;
*)
  echo "usage: $0 [update]" >&2
  exit 2
  ;;
esac
