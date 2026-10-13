# A tmux server keeps the directory it was started from as its cwd for life.
# Started in a folder that's later removed (a try folder, a worktree), tmux
# then ignores -c and opens every new pane in that deleted folder. So a
# command that would start the server runs tmux-ensure-server first, which
# starts it from $HOME (and warns when the running one's folder is gone); the
# session asked for still opens here, since a new session takes the client's
# directory. The command is found past tmux's own options (-u, -2, -f file…),
# abbreviated or not (new-s). Commands that don't start a server (ls,
# kill-server) and other sockets (-L, -S) pass through. Defined only where tmux
# is installed, so a missing one still gets zsh's command-not-found.
if (( $+commands[tmux] )) && [[ -x ~/.local/bin/tmux-ensure-server ]]; then
  tmux() {
    local -i i=1
    while (( i <= $# )); do
      case ${@[i]} in
        -[LS]*) command tmux "$@"; return ;;
        -[cfT]) (( i += 2 )) ;;
        -[cfT]?* | -[2CDlNuvV]*) (( i++ )) ;;
        --) (( i++ )); break ;;
        *) break ;;
      esac
    done
    if (( i > $# )) || [[ ${@[i]} == (new|new-s*|start|start-s*) ]]; then
      ~/.local/bin/tmux-ensure-server
    fi
    command tmux "$@"
  }
fi

alias t="tmux"
alias ta='tmux-attach' # this uses an fzf-powered script
alias ts='tmux new-session -s'
alias tl='tmux list-sessions'
alias tksv='tmux kill-server'
alias tkss='tmux kill-session -t'
alias tmuxconf='$EDITOR $ZSH_TMUX_CONFIG'

alias tr="tmuxinator"
alias tre="tmuxinator edit"
alias trs="tmuxinator start"
