# mattmc3/zshrc.d sources conf.d after ohmyzsh's fzf plugin, so this wins.
source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/theme.sh"

# FZF_DEFAULT_OPTS is picked once per shell, so a shell opened before the
# system appearance changed kept the old palette. fzf's widgets (Ctrl+R,
# Ctrl+T, Alt+C) build their options through __fzf_defaults each time they
# open, so re-pick the palette there. It runs in the widget's own subshell,
# and the appearance check costs ~12ms, only paid when a widget opens.
if (( $+functions[__fzf_defaults] )); then
  functions[_fzf_defaults_orig]=$functions[__fzf_defaults]
  __fzf_defaults() {
    fzf-theme
    _fzf_defaults_orig "$@"
  }
fi
