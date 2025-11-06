export PATH=$PATH:$HOME/.local/bin

export EDITOR='nvim'

#vim
alias v="vim"
alias nv="nvim"
alias update-nvim-stable='asdf uninstall neovim stable && asdf install neovim stable'
alias update-nvim-nightly='asdf uninstall neovim nightly && asdf install neovim nightly'
alias update-nvim-master='asdf uninstall neovim ref:master && asdf install neovim ref:master'

#ranger
export PYGMENTIZE_STYLE=one-dark
alias ranger="PYGMENTIZE_STYLE=one-dark ranger"

#git
alias tigs="tig status"
alias tiga="tig --all"
alias gcleanfd='git clean -f -d'

#lazygit
alias lg="lazygit"

alias c="clear"

alias fd="fdfind"

alias rm='echo "use trash instead of rm. use rm with a prependend slash if you really want to"; false'

alias cd="z"

export VSCODE_JAVA_DEPENDENCY_PATH="$HOME/Repos/vscode-java-dependency"
