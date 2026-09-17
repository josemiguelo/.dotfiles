# Tokyo Night colors for fzf, verbatim from tokyonight.nvim's extras/fzf.
# mattmc3/zshrc.d sources conf.d after ohmyzsh's fzf plugin, so this wins.
# FZF_DEFAULT_OPTS is read when fzf starts, so a shell that was already open
# when the system appearance changed needs `fzf-theme` re-run by hand.

fzf-theme() {
  local shared="--highlight-line --info=inline-right --ansi --layout=reverse --border=none"
  local dark=1

  # only macOS reports appearance; elsewhere stay on the night palette
  if [[ "$OSTYPE" == darwin* ]]; then
    [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]] || dark=0
  fi

  if (( dark )); then
    export FZF_DEFAULT_OPTS="$shared \
      --color=bg+:#283457 \
      --color=bg:#16161e \
      --color=border:#27a1b9 \
      --color=fg:#c0caf5 \
      --color=gutter:#16161e \
      --color=header:#ff9e64 \
      --color=hl+:#2ac3de \
      --color=hl:#2ac3de \
      --color=info:#545c7e \
      --color=marker:#ff007c \
      --color=pointer:#ff007c \
      --color=prompt:#2ac3de \
      --color=query:#c0caf5:regular \
      --color=scrollbar:#27a1b9 \
      --color=separator:#ff9e64 \
      --color=spinner:#ff007c"
  else
    export FZF_DEFAULT_OPTS="$shared \
      --color=bg+:#b7c1e3 \
      --color=bg:#d0d5e3 \
      --color=border:#4094a3 \
      --color=fg:#3760bf \
      --color=gutter:#d0d5e3 \
      --color=header:#b15c00 \
      --color=hl+:#188092 \
      --color=hl:#188092 \
      --color=info:#8990b3 \
      --color=marker:#d20065 \
      --color=pointer:#d20065 \
      --color=prompt:#188092 \
      --color=query:#3760bf:regular \
      --color=scrollbar:#4094a3 \
      --color=separator:#b15c00 \
      --color=spinner:#d20065"
  fi
}

fzf-theme
