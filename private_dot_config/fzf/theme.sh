# Tokyo Night colors for fzf, from tokyonight.nvim's extras/fzf. Deviations:
# bg and gutter are -1 to inherit the terminal background, since kitty only
# keeps the default background transparent; pointer and marker are blue rather
# than upstream's pink. With a -1 gutter fzf still draws its '▌' gutter glyph,
# in the terminal's default foreground, so every row gets a bright stripe in
# dark mode; a blank gutter glyph avoids it. fg+ is set explicitly because
# fzf's fallback (256-color 254) is near-white, unreadable on the light bg+.
#
# Sourced by zsh (conf.d/fzf.zsh) and by tmux-attach, which runs under bash, so
# keep this to syntax both shells share.

fzf-theme() {
  # bg is -1 so the picker has no fill of its own; the border is what separates
  # it from whatever is behind it.
  local shared="--highlight-line --info=inline-right --ansi --layout=reverse --border=rounded --gutter=' '"
  local dark=1

  # only macOS reports appearance; elsewhere stay on the storm palette
  if [[ "$OSTYPE" == darwin* ]]; then
    [[ "$(defaults read -g AppleInterfaceStyle 2>/dev/null)" == Dark ]] || dark=0
  fi

  if (( dark )); then
    export FZF_DEFAULT_OPTS="$shared \
      --color=bg+:#2e3c64 \
      --color=bg:-1 \
      --color=border:#29a4bd \
      --color=fg:#c0caf5 \
      --color=fg+:#c0caf5 \
      --color=gutter:-1 \
      --color=header:#ff9e64 \
      --color=hl+:#2ac3de \
      --color=hl:#2ac3de \
      --color=info:#545c7e \
      --color=marker:#7aa2f7 \
      --color=pointer:#7aa2f7 \
      --color=prompt:#2ac3de \
      --color=query:#c0caf5:regular \
      --color=scrollbar:#29a4bd \
      --color=separator:#ff9e64 \
      --color=spinner:#ff007c"
  else
    export FZF_DEFAULT_OPTS="$shared \
      --color=bg+:#b7c1e3 \
      --color=bg:-1 \
      --color=border:#4094a3 \
      --color=fg:#3760bf \
      --color=fg+:#3760bf \
      --color=gutter:-1 \
      --color=header:#b15c00 \
      --color=hl+:#188092 \
      --color=hl:#188092 \
      --color=info:#8990b3 \
      --color=marker:#2e7de9 \
      --color=pointer:#2e7de9 \
      --color=prompt:#188092 \
      --color=query:#3760bf:regular \
      --color=scrollbar:#4094a3 \
      --color=separator:#b15c00 \
      --color=spinner:#d20065"
  fi
}

fzf-theme
