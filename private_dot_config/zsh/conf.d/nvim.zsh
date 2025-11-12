nvim() {
  if [[ "$1" == "." && "$#" == 1 ]]; then
    echo "⚠️  Heads up: You don't need 'nvim .' to open the current directory."
    echo "Just 'nvim' is sufficient to open the Neovim file browser in the current directory."
  else
    ~/.asdf/shims/nvim "$@"
  fi
}

export EDITOR='nvim'

#vim
alias v="vim"
alias nv="nvim"
alias update-nvim-stable='asdf uninstall neovim stable && asdf install neovim stable'
alias update-nvim-nightly='asdf uninstall neovim nightly && asdf install neovim nightly'
alias update-nvim-master='asdf uninstall neovim ref:master && asdf install neovim ref:master'
