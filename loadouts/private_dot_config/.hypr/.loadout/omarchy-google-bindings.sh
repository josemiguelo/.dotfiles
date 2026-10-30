#!/bin/sh
# Omarchy's email and calendar keys open HEY (default/hypr/bindings/
# applications.lua). This rebinds them to Gmail and Google Calendar in
# ~/.config/hypr/bindings.lua, Omarchy's personal-bindings file, the way its
# own comments say: hl.unbind the key, then bind it again (two binds on one
# key would both fire). The check doesn't read the file's text:
# hypr-option.lua evaluates the whole Lua config and reports what each key
# runs. Install confirms it in the running Hyprland when there is one — by
# description: with a Lua config, hyprctl binds shows every binding as a Lua
# function reference, never the command, so each key's one binding must carry
# the description given here.
# Modes: `check` / `install` (default).
set -eu

CONF=$HOME/.config/hypr/bindings.lua
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../../.omarchy/.loadout/lib/hypr-option.lua
. "$HERE/../../.omarchy/.loadout/lib/hypr-live.sh"

BEGIN="-- >>> Managed by loadout (omarchy-google-bindings)"
END="-- <<< Managed by loadout (omarchy-google-bindings)"
# The block an earlier version appended, unmarked at its end: from its
# comment through its last bind. Install replaces it like its own.
LEGACY="-- Managed by loadout (omarchy-google-bindings)"
LEGACY_LAST='o.bind("SUPER + SHIFT + C"'

MAIL=https://mail.google.com/
COMPOSE='https://mail.google.com/mail/?view=cm&fs=1'
CALENDAR=https://calendar.google.com/

# What o.bind makes of { webapp = url }.
webapp() {
  echo "omarchy-launch-webapp '$1'"
}

# The block: each key unbound from HEY, then bound to Google.
block() {
  echo "$BEGIN"
  echo "-- Gmail and Google Calendar in HEY's place"
  echo "-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-google-bindings.sh)."
  echo 'hl.unbind("SUPER + SHIFT + E")'
  echo "o.bind(\"SUPER + SHIFT + E\", \"Gmail\", { webapp = \"$MAIL\" })"
  echo 'hl.unbind("SUPER + SHIFT + ALT + E")'
  echo "o.bind(\"SUPER + SHIFT + ALT + E\", \"New Gmail message\", { webapp = \"$COMPOSE\" })"
  echo 'hl.unbind("SUPER + SHIFT + C")'
  echo "o.bind(\"SUPER + SHIFT + C\", \"Google Calendar\", { webapp = \"$CALENDAR\" })"
  echo "$END"
}

# CONF without any block of ours (marked, or the old unmarked one), then the
# current block; written whole through a temp file, so it's never half there.
write_block() {
  mkdir -p "$(dirname "$CONF")"
  tmp=$(mktemp "$CONF.XXXXXX")
  {
    if [ -f "$CONF" ]; then
      # Blank lines are held until a kept line follows, so the ones left at
      # the end (before an old block) don't pile up rewrite after rewrite.
      # The old block also ends at its first line that isn't a comment, an
      # unbind or a bind (kept): one edited by hand never swallows the rest.
      awk -v b="$BEGIN" -v e="$END" -v l="$LEGACY" -v ll="$LEGACY_LAST" '
        $0 == b { skip = 1 } index($0, l) == 1 { skip = 2 }
        skip == 2 && $0 !~ /^(--|hl\.|o\.)/ { skip = 0 }
        !skip && /^[[:space:]]*$/ { blanks = blanks "\n"; next }
        !skip { printf "%s%s\n", blanks, $0; blanks = "" }
        skip == 1 && $0 == e { skip = 0 }
        skip == 2 && index($0, ll) == 1 { skip = 0 }' "$CONF"
    fi
    echo
    block
  } >"$tmp"
  # mktemp makes it 0600; the file keeps its own mode (0644 when new).
  if [ -f "$CONF" ]; then chmod --reference="$CONF" "$tmp"; else chmod 644 "$tmp"; fi
  mv "$tmp" "$CONF"
}

# Every key runs exactly the one command; fails (the probe says why) when the
# config can't be evaluated.
bound() {
  [ "$(lua "$PROBE" "bind:SUPER + SHIFT + E")" = "$(webapp "$MAIL")" ] &&
    [ "$(lua "$PROBE" "bind:SUPER + SHIFT + ALT + E")" = "$(webapp "$COMPOSE")" ] &&
    [ "$(lua "$PROBE" "bind:SUPER + SHIFT + C")" = "$(webapp "$CALENDAR")" ]
}

case "${1:-install}" in
check)
  bound
  ;;
install)
  lua "$PROBE" "bind:SUPER + SHIFT + E" >/dev/null || exit 1
  # Rewritten whenever a key is off: an edited URL replaces the block, not
  # a second one after it.
  bound || write_block
  bound || { echo "the email/calendar keys still don't open Google after $CONF: something loaded later binds them" >&2; exit 1; }
  sig=$(live_instance)
  if [ -n "$sig" ]; then
    HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl -q reload
    live=$(HYPRLAND_INSTANCE_SIGNATURE=$sig hyprctl binds -j)
    # modmask: SUPER 64 + SHIFT 1 (+ ALT 8).
    for want in "65 E Gmail" "73 E New Gmail message" "65 C Google Calendar"; do
      set -- $want
      mask=$1 key=$2
      shift 2
      got=$(printf '%s' "$live" | jq -r --argjson m "$mask" --arg k "$key" \
        '[.[] | select(.modmask == $m and .key == $k) | .description] | join("|")')
      [ "$got" = "$*" ] ||
        { echo "the running Hyprland binds key $key (modmask $mask) to '$got', not '$*'" >&2; exit 1; }
    done
  else
    echo "Hyprland isn't reachable from here; the keys change at the next login."
  fi
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
