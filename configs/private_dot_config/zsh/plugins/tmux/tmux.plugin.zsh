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

# C-M-a runs the picker outside tmux; inside tmux the root-table binding in
# tmux.conf takes the same key first, so kitty can send it either way
_tmux_attach_widget() {
  zle push-line
  BUFFER='tmux-attach'
  zle accept-line
}
zle -N _tmux_attach_widget
bindkey '^[^A' _tmux_attach_widget
