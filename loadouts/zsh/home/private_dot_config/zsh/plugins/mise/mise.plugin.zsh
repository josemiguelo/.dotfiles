# mise puts the tool versions from ~/.config/mise/config.toml on PATH (and
# exports JAVA_HOME and friends) from a precmd hook. Not zcache'd like zoxide
# or starship: `mise activate` writes the current PATH into its own output, so
# a cached copy would restore a stale PATH in every new shell.
(( $+commands[mise] )) || return
eval "$(mise activate zsh)"
