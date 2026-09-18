# mattmc3/zshrc.d sources conf.d after ohmyzsh's fzf plugin, so this wins.
# FZF_DEFAULT_OPTS is read when fzf starts, so a shell that was already open
# when the system appearance changed needs `fzf-theme` re-run by hand.
source "${XDG_CONFIG_HOME:-$HOME/.config}/fzf/theme.sh"
