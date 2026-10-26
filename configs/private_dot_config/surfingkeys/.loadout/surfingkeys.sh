#!/bin/sh
# Surfingkeys in Brave's Default profile, allowed to read file URLs so it can
# load ~/.config/surfingkeys/surfingkeys.js. Brave keeps both in its profile
# (and signs its preferences), so nothing here can set them: `install` lists
# the steps to do in Brave. The "Load settings from" path itself lives in the
# extension's LevelDB storage, which `check` doesn't read.
# Modes: `check` / `install` (default).
set -eu

id=gfbliohnnapiefjpjlpjnehglfpaknnc
profile="${XDG_CONFIG_HOME:-$HOME/.config}/BraveSoftware/Brave-Browser/Default"
config="${XDG_CONFIG_HOME:-$HOME/.config}/surfingkeys/surfingkeys.js"

ready() {
  for prefs in "$profile/Preferences" "$profile/Secure Preferences"; do
    [ -f "$prefs" ] &&
      jq -e --arg id "$id" '.extensions.settings[$id].newAllowFileAccess == true' "$prefs" >/dev/null 2>&1 &&
      return 0
  done
  return 1
}

case "${1:-install}" in
check)
  ready
  ;;
install)
  ready && exit 0
  cat >&2 <<EOF
Surfingkeys needs setting up in Brave, by hand:
  1. Install it: https://chromewebstore.google.com/detail/surfingkeys/$id
  2. brave://extensions/?id=$id → turn on "Allow access to file URLs"
  3. Surfingkeys' settings → Advanced mode → "Load settings from":
     file://$config
EOF
  exit 1
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
