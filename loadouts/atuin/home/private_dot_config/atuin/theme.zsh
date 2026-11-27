# atuin's theme is fixed in its config, so pick it each time the search opens:
# a shell opened before the system appearance changed follows it too. Sourced by
# .zshrc after atuin's init, which defines _atuin_search; every search widget
# goes through that. Same signal as fzf/theme.sh (appearance-is-dark, ~12ms);
# without it, the dark theme. The variables win over ~/.atuin/config.toml.
if (( $+functions[_atuin_search] )); then
  functions[_atuin_search_orig]=$functions[_atuin_search]
  _atuin_search() {
    local -x ATUIN_THEME_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/atuin/themes"
    local -x ATUIN_THEME__NAME=tokyonight-storm
    local appearance=${commands[appearance-is-dark]:-$HOME/.local/bin/appearance-is-dark}
    if [[ -x $appearance ]] && ! $appearance; then
      ATUIN_THEME__NAME=tokyonight-day
    fi
    _atuin_search_orig "$@"
  }
fi
