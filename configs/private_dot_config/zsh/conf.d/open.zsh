# open: xdg-open detached from the terminal, like macOS's open — ported from
# Omarchy's bash aliases (default/bash/aliases). Linux only: macOS has open.
if [[ $OSTYPE == linux* ]] && (( $+commands[xdg-open] )); then
  open() {
    xdg-open "$@" >/dev/null 2>&1 &!
  }
fi
