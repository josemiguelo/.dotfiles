# try: pick or create a folder in ~/Work/tries and cd this shell into it. The
# picker prints a script to eval on a selection, and "Cancelled." with exit 1
# on Esc or Ctrl-C. This replaces the function `try init` generates, which
# echoes that message and returns echo's 0, so a caller (start-loadout)
# couldn't tell a cancel from a pick. try's picker has fixed colors made for
# dark terminals (lib/tui.rb's 256-color palette: a dark grey selection bar,
# bright yellow matches) and no theme setting, so on a light desktop
# (appearance-is-dark) it runs with NO_COLOR: plain text, the selected row
# still marked with →.
if (( $+commands[try] )); then
  try() {
    if (( $+commands[appearance-is-dark] )) && ! appearance-is-dark; then
      local -x NO_COLOR=1
    fi
    local out
    if ! out=$(command try exec --path ~/Work/tries "$@" 2>/dev/tty); then
      [[ -n $out ]] && print -r -- $out
      return 1
    fi
    eval "$out"
  }
fi
