# Disable WezTerm shell integration if not running in WezTerm
if [[ "$TERM_PROGRAM" != "WezTerm" ]]; then
  unset WEZTERM_PANE WEZTERM_EXECUTABLE WEZTERM_UNIX_SOCKET
fi

#git
alias tigs="tig status"
alias tiga="tig --all"
alias gcleanfd='git clean -f -d'

#lazygit
alias lg="lazygit"

alias c="clear"

alias fd="fdfind"

alias rm='echo "use trash instead of rm, or \rm"; false'

alias cd="z"
