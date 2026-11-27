nvim() {
  if [[ "$1" == "." && "$#" == 1 ]]; then
    echo "⚠️  Heads up: You don't need 'nvim .' to open the current directory."
    echo "Just 'nvim' is sufficient to open the Neovim file browser in the current directory."
  else
    command nvim "$@"
  fi
}

export EDITOR='nvim'
# sudoedit too, as Omarchy's bash setup does (default/bash/envs).
export SUDO_EDITOR="$EDITOR"

#vim
alias v="vim"
alias nv="nvim"
# stable and nightly are moving tags: --force downloads them again.
alias update-nvim-stable='mise install --force neovim@stable'
alias update-nvim-nightly='mise install --force neovim@nightly'
