# eza as ls, ported from Omarchy's bash aliases (default/bash/aliases):
# Omarchy only sets them up for bash, so zsh lost them. conf.d loads after
# oh-my-zsh, so these replace its ls/lsa. Only where eza is installed.
if (( $+commands[eza] )); then
  alias ls='eza -lh --group-directories-first --icons=auto'
  alias lsa='ls -a'
  alias lt='eza --tree --level=2 --long --icons --git'
  alias lta='lt -a'
fi
