# bat, the way Omarchy's bash setup uses it (default/bash/envs): the ansi
# theme, so bat draws with the terminal's own 16 colors and follows kitty's
# light/dark theme, and colored man pages through bat. Plus cat as bat
# (Omarchy doesn't): interactive shells only, plain style so copied output
# has no line numbers or borders, never paging. Only where bat is installed.
if (( $+commands[bat] )); then
  export BAT_THEME=ansi
  export MANROFFOPT="-c"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  alias cat='bat --paging=never --style=plain'
fi
