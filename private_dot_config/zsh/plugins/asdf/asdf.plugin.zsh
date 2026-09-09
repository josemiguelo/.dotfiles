(( $+commands[asdf] )) || return

export ASDF_DATA_DIR="${ASDF_DATA_DIR:-$HOME/.asdf}"

# Add shims to the front of the path, removing if already present.
path=("$ASDF_DATA_DIR/shims" ${path:#$ASDF_DATA_DIR/shims})

# ohmyzsh's asdf plugin regenerates this on every startup; only refresh it when
# asdf itself changes. compinit picks the file up from $ZSH_CACHE_DIR/completions
# on the next shell, so bind it by hand the first time we create it.
if [[ ! -s "$ZSH_CACHE_DIR/completions/_asdf" || ${commands[asdf]} -nt "$ZSH_CACHE_DIR/completions/_asdf" ]]; then
  asdf completion zsh >| "$ZSH_CACHE_DIR/completions/_asdf"
  typeset -g -A _comps
  autoload -Uz _asdf
  _comps[asdf]=_asdf
fi
