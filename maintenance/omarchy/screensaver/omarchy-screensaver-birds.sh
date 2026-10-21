#!/bin/sh
# Omarchy's screensaver as a flock of birds (github.com/clainstone/cbirds)
# instead of a random TTE effect from ttfx. In Kitty and Ghostty, small
# sprite birds draw Omarchy's logo ($OMARCHY_PATH/logo.svg, with a
# transparent margin so it sits in the middle third), hold it, fly off as a
# murmuration and draw it again. The logo is painted in bands of the current
# theme's colors (its colors.toml: red, orange, yellow, green, cyan, blue,
# magenta, read at every start, so it follows a theme change), white when the
# theme names none; cbirds keeps up to eight colors of a picture, and a bird
# keeps its color while it flies. Other terminals have no sprites, so
# there the branding text (~/.config/omarchy/branding/screensaver.txt)
# itself takes off letter by letter and lands back, which looks blocky but
# works in braille.
#
# cbirds holds a picture 30 to 45 seconds before letting go, which on a
# screensaver reads as frozen, and has no option for it. So cbirds is built
# from its checkout in ~/Repos/gh/clainstone/cbirds (cloned over https when
# missing), from a local branch, omarchy-hold: its release tag with
# cbirds-hold.patch committed on top, which adds `--hold SECONDS`. The build
# takes the branch's tree (git archive), not the working copy, so whatever is
# checked out there, local work included, doesn't reach the binary; it goes
# into ~/.local/bin, and its version says `+hold`. The check reads that, the
# remote, and whether the branch carries exactly the patch (compared by `git
# patch-id`); a branch that doesn't is left alone and install stops, since
# it may hold work. Goes back to the brew tap (clainstone/tap) if upstream
# takes the option.
#
# omarchy-launch-screensaver runs `omarchy-screensaver` in a terminal it
# starts from Hyprland, so a replacement in the directory
# omarchy-command-overrides puts first on that PATH takes its place. cbirds
# lays text out as a terminal prints it, from the top-left corner, so the
# replacement pads the text to the middle of the window first, once the
# window has its real size. `cbirds --screensaver` quits on any key, click or
# pointer movement itself; the replacement still quits when the window loses
# focus, as Omarchy's does. The launcher itself is Omarchy's and still
# requires ttfx to be installed. The check requires the session to actually
# run the replacement.
# Modes: `check` / `install` (default).
set -eu

COMMAND=omarchy-screensaver
HERE="$(cd "$(dirname "$0")" && pwd)"
PROBE=$HERE/../lib/hypr-option.lua
. "$HERE/../lib/omarchy-overrides-lib.sh"
WRAPPER=$OVERRIDES_DIR/$COMMAND
REPO=https://github.com/clainstone/cbirds.git
CHECKOUT=$HOME/Repos/gh/clainstone/cbirds
TAG=v1.7.0
TAG_COMMIT=dc22807b132c9a8ca819413faacf25973ecb376a
BRANCH=omarchy-hold
PATCH=$HERE/cbirds-hold.patch
BIN=$HOME/.local/bin/cbirds
BUILT="cbirds ${TAG#v}+hold"

wrapper_text() {
  cat <<WRAPPER_EOF
#!/bin/bash
# Managed by loadout (omarchy-screensaver-birds): Omarchy's screensaver with
# the logo flocking away as birds and coming back (cbirds), in place of
# ttfx's effects.

screensaver_in_focus() {
  hyprctl activewindow -j | jq -e '.class == "org.omarchy.screensaver"' >/dev/null 2>&1
}

show_cursor() {
  hyprctl eval 'hl.config({ cursor = { invisible = false } })' &>/dev/null || hyprctl keyword cursor:invisible false &>/dev/null || true
}

exit_screensaver() {
  show_cursor
  [[ -n \${watcher:-} ]] && kill "\$watcher" 2>/dev/null
  pkill -x cbirds 2>/dev/null
  pkill -f '[o]rg.omarchy.screensaver' 2>/dev/null
  exit 0
}

trap exit_screensaver SIGINT SIGTERM SIGHUP SIGQUIT
# Whatever ends this script, the pointer comes back.
trap show_cursor EXIT

printf '\033]11;rgb:00/00/00\007'

hyprctl eval 'hl.config({ cursor = { invisible = true } })' &>/dev/null || hyprctl keyword cursor:invisible true &>/dev/null

# Start once the window has its real size, not the pty's first 80x24.
deadline=\$((SECONDS + 2))
while ((SECONDS < deadline)) && [[ \$(stty size 2>/dev/null) == "24 80" ]]; do
  sleep 0.02
done

work=\$(mktemp -d "\${XDG_RUNTIME_DIR:-/tmp}/omarchy-screensaver.XXXXXX")

case \$TERM in
xterm-kitty | xterm-ghostty)
  # Small sprite birds drawing the logo, a third of the screen wide, in bands
  # of the theme's colors.
  theme=~/.local/state/omarchy/current/theme/colors.toml
  bands=()
  for color in red orange yellow green cyan blue magenta; do
    hex=\$(sed -n "s/^\$color *= *\"\(#[0-9a-fA-F]\{6\}\)\"/\1/p" "\$theme" 2>/dev/null)
    [[ -n \$hex ]] && bands+=("xc:\$hex")
  done
  ((\${#bands[@]})) || bands=(xc:white)
  sed 's/#000/#fff/g' "\${OMARCHY_PATH:-/usr/share/omarchy}/logo.svg" | rsvg-convert -w 1200 -o "\$work/mask.png"
  height=\$(magick identify -format %h "\$work/mask.png")
  # The mask's alpha cuts the logo out of the bands; -compose over again
  # before -extent, which composes too.
  magick -size \$((1200 / \${#bands[@]} + 1))x"\$height" "\${bands[@]}" +append -crop 1200x"\$height"+0+0 +repage \\
    "\$work/mask.png" -compose CopyOpacity -composite \\
    -compose over -background none -gravity center -extent 2000x800 +repage PNG32:"\$work/logo.png"
  flock=(--picture "\$work/logo.png" --render kitty --shape bird -n 1500 --size 6 --hold 6)
  ;;
*)
  # The text in the middle of the window: cbirds puts it where it's printed.
  branding=~/.config/omarchy/branding/screensaver.txt
  read -r rows cols < <(stty size)
  width=\$(wc -L < "\$branding")
  height=\$(wc -l < "\$branding")
  {
    for ((i = 0; i < (rows - height) / 2; i++)); do echo; done
    sed "s/^/\$(printf '%*s' \$((cols > width ? (cols - width) / 2 : 0)) '')/" "\$branding"
  } > "\$work/text"
  flock=(--text "\$work/text")
  ;;
esac

# Gone from focus, the screensaver goes, as Omarchy's does.
while screensaver_in_focus; do sleep 1; done && pkill -x cbirds &
watcher=\$!
"$BIN" --screensaver "\${flock[@]}"
rm -rf "\$work"
exit_screensaver
WRAPPER_EOF
}

built() {
  [ -x "$BIN" ] && [ "$("$BIN" --version 2>/dev/null)" = "$BUILT" ]
}

cloned() {
  [ -d "$CHECKOUT/.git" ] && [ "$(git -C "$CHECKOUT" config --get remote.origin.url)" = "$REPO" ]
}

# The branch is the tag and the patch, nothing more.
patched() {
  [ "$(git -C "$CHECKOUT" rev-parse --verify --quiet "$BRANCH~1^{commit}")" = "$TAG_COMMIT" ] &&
    [ "$(git -C "$CHECKOUT" diff "$TAG_COMMIT" "$BRANCH" | git patch-id --stable | cut -d' ' -f1)" = \
      "$(git patch-id --stable < "$PATCH" | cut -d' ' -f1)" ]
}

branch_exists() {
  git -C "$CHECKOUT" rev-parse --verify --quiet "refs/heads/$BRANCH" >/dev/null
}

installed() {
  [ -x "$WRAPPER" ] && [ "$(cat "$WRAPPER")" = "$(wrapper_text)" ] && override_active "$COMMAND"
}

case "${1:-install}" in
check)
  cloned && patched && built && installed
  ;;
install)
  if [ ! -d "$CHECKOUT/.git" ]; then
    mkdir -p "$(dirname "$CHECKOUT")"
    git clone --quiet "$REPO" "$CHECKOUT"
  fi
  cloned || git -C "$CHECKOUT" config remote.origin.url "$REPO"
  git -C "$CHECKOUT" rev-parse --verify --quiet "$TAG_COMMIT^{commit}" >/dev/null ||
    git -C "$CHECKOUT" fetch --quiet origin tag "$TAG"
  [ "$(git -C "$CHECKOUT" rev-parse "$TAG^{commit}")" = "$TAG_COMMIT" ] ||
    { echo "$REPO $TAG isn't $TAG_COMMIT any more" >&2; exit 1; }
  if ! branch_exists; then
    # A worktree of its own, so the patch is committed without touching the
    # checkout's working copy.
    tmp=$(mktemp -d)
    trap 'git -C "$CHECKOUT" worktree remove --force "$tmp" 2>/dev/null; rm -rf "$tmp"' EXIT
    git -C "$CHECKOUT" worktree add --quiet -b "$BRANCH" "$tmp" "$TAG_COMMIT"
    git -C "$tmp" apply --index "$PATCH"
    git -C "$tmp" commit --quiet -m "Add --hold SECONDS: how long a sign is held

Managed by loadout (omarchy-screensaver-birds), from cbirds-hold.patch."
    git -C "$CHECKOUT" worktree remove "$tmp"
    trap - EXIT
  fi
  patched || { echo "$CHECKOUT's $BRANCH isn't $TAG with cbirds-hold.patch: move it aside (git branch -m $BRANCH …) and install again" >&2; exit 1; }
  if ! built; then
    src=$(mktemp -d)
    trap 'rm -rf "$src"' EXIT
    git -C "$CHECKOUT" archive "$BRANCH" | tar -x -C "$src"
    make -s -C "$src" install PREFIX="$HOME/.local"
    built || { echo "$BIN doesn't say $BUILT after the build" >&2; exit 1; }
  fi
  mkdir -p "$OVERRIDES_DIR"
  wrapper_text > "$WRAPPER"
  chmod 755 "$WRAPPER"
  installed || { echo "the session doesn't run $WRAPPER: is omarchy-command-overrides installed?" >&2; exit 1; }
  echo "Try it: omarchy-launch-screensaver force"
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
