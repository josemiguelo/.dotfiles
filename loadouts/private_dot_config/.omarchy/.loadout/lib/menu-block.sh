# Sourced by the scripts that keep entries of their own in the Omarchy menu
# (Keystroke serves it): a block in ~/.config/omarchy/extensions/
# omarchy-menu.jsonc, right after the object's opening brace, between marker
# comments named for the script. The entries end in commas; the menu's
# reader drops trailing ones.
#   menu_block_in_place <name> <comment> <entries-file>   the block is as written
#   menu_block_write    <name> <comment> <entries-file>   (re)writes it

MENU=$HOME/.config/omarchy/extensions/omarchy-menu.jsonc

menu_block() {
  echo "  // >>> Managed by loadout ($1)"
  echo "  // $2"
  cat "$3"
  echo "  // <<< Managed by loadout ($1)"
}

# The block as the file has it, or nothing.
menu_block_current() {
  [ -f "$MENU" ] || return 0
  awk -v b="  // >>> Managed by loadout ($1)" -v e="  // <<< Managed by loadout ($1)" \
    '$0 == b { keep = 1 } keep { print } $0 == e { keep = 0 }' "$MENU"
}

menu_block_in_place() {
  [ "$(menu_block_current "$1")" = "$(menu_block "$1" "$2" "$3")" ]
}

menu_block_write() {
  mkdir -p "$(dirname "$MENU")"
  [ -f "$MENU" ] || printf '{\n}\n' > "$MENU"
  grep -q '^[[:space:]]*{' "$MENU" || { echo "$MENU has no opening brace to put the menu entries after" >&2; return 1; }
  # The file without the old block, the block right after the first line
  # that opens the object.
  mb_rest=$(awk -v b="  // >>> Managed by loadout ($1)" -v e="  // <<< Managed by loadout ($1)" \
    '$0 == b { skip = 1 } !skip { print } $0 == e { skip = 0 }' "$MENU")
  {
    printf '%s\n' "$mb_rest" | awk '/^[[:space:]]*\{/ { print; exit } { print }'
    menu_block "$1" "$2" "$3"
    printf '%s\n' "$mb_rest" | awk 'found { print } !found && /^[[:space:]]*\{/ { found = 1 }'
  } > "$MENU.tmp"
  mv "$MENU.tmp" "$MENU"
}
