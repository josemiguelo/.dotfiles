# Tab completion for the omarchy command (groups, then commands in a group),
# from Omarchy's bash completion (default/bash/completions) through zsh's
# bash compatibility layer. That file ends with a bash-only line that makes
# zsh register empty completions for commands named -A, -I, -X and omarchy-*,
# so those are dropped again; and its function calls bash's shopt, which zsh
# doesn't have, so a stand-in exists only while it runs. Omarchy only.
if [[ -r ${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/completions ]] && (( $+functions[compdef] )); then
  autoload -U bashcompinit && bashcompinit
  source "${OMARCHY_PATH:-/usr/share/omarchy}/default/bash/completions"
  compdef -d -- -A -I -X 'omarchy-*'

  _omarchy_complete_zsh() {
    shopt() { :; }
    _omarchy_complete "$@"
    unfunction shopt
  }
  complete -o default -F _omarchy_complete_zsh omarchy
fi
