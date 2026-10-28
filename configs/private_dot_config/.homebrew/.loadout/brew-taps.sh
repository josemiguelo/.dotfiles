#!/bin/sh
# Taps one third-party Homebrew tap and trusts it, for this user. Trust is per
# user (~/.homebrew/trust.json), so a tap another account trusted still fails
# here with "Refusing to load ... from untrusted tap". Each tap is declared by
# the program that installs from it, in that program's own fragment, so this
# script takes the tap as an argument and knows no list of its own.
#
#   brew-taps.sh check <tap>                    exit 0 when the tap is tapped and trusted
#   brew-taps.sh install <tap>                  tap and trust it (a no-op when it already is)
#   brew-taps.sh install <tap> <name> [--cask]  then install <name> (its full path) from it
set -eu

BREW="sh $(dirname "$0")/brew.sh"

usage() { echo "usage: $0 check <tap> | install <tap> [<name> [--cask]]" >&2; exit 2; }
[ $# -ge 2 ] && [ $# -le 4 ] || usage

trusted() { $BREW tap-info "$1" 2>/dev/null | grep -qx Trusted; }

case "$1" in
  check) trusted "$2" ;;
  install)
    $BREW tap-info "$2" 2>/dev/null | grep -q "Installed" || $BREW tap "$2"
    trusted "$2" || $BREW trust --tap "$2"
    if [ $# -ge 3 ]; then
      if [ "${4:-}" = --cask ]; then $BREW install --cask "$3"; else $BREW install "$3"; fi
    fi
    ;;
  *) usage ;;
esac
