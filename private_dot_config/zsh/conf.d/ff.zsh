# ff: fzf over the files below, with a preview — bat for text and, straight
# in kitty, the image itself (kitty icat; through tmux it can't draw, so bat
# there) — and eff: open what ff picks in $EDITOR. Ported from Omarchy's
# bash aliases (default/bash/aliases); eff opens nothing when ff is
# cancelled.
if (( $+commands[fzf] && $+commands[bat] )); then
  ff() {
    if [[ $TERM == xterm-kitty ]]; then
      fzf --preview 'case $(file --mime-type -b {}) in image/*) kitty icat --clear --transfer-mode=memory --stdin=no --place=${FZF_PREVIEW_COLUMNS}x${FZF_PREVIEW_LINES}@0x0 {} ;; *) bat --style=numbers --color=always {} ;; esac' "$@"
    else
      fzf --preview 'bat --style=numbers --color=always {}' "$@"
    fi
  }

  eff() {
    local file
    file=$(ff "$@") && [[ -n $file ]] && $EDITOR "$file"
  }
fi
