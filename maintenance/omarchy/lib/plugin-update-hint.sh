# Sourced by the scripts that build on Omarchy shell plugins installed from
# git (~/.config/omarchy/plugins/<id>, by omarchy-plugins). Nothing updates
# those checkouts but `omarchy plugin update` (or `loadout outdated`), while
# these scripts, and omarchy-bar-icons' patches, follow upstream: a checkout
# left behind shows up as a missing file or a patch that no longer applies.
# plugin_update_hint names the ones that are behind, for a script to print
# after it fails; only then, since it fetches each one.
#
# omarchy-plugin-update only fast-forwards (`git merge --ff-only FETCH_HEAD`
# on whatever branch is checked out), so a checkout with commits of its own,
# or uncommitted changes, gets told to catch up by hand instead.

# plugin_update_hint <id>...: on stderr, a line for each id that is a git
# checkout behind its remote's HEAD. Ids without one (Omarchy's built-ins,
# omarchy-bar-icons' clones) are skipped. Always succeeds.
plugin_update_hint() {
  for hint_id in "$@"; do
    hint_dir=$HOME/.config/omarchy/plugins/$hint_id
    [ -d "$hint_dir/.git" ] || continue
    git -C "$hint_dir" fetch --quiet origin HEAD 2>/dev/null || continue
    hint_behind=$(git -C "$hint_dir" rev-list --count HEAD..FETCH_HEAD 2>/dev/null) || continue
    [ "$hint_behind" -gt 0 ] || continue
    hint_ahead=$(git -C "$hint_dir" rev-list --count FETCH_HEAD..HEAD 2>/dev/null) || hint_ahead=0
    if [ "$hint_ahead" -gt 0 ]; then
      hint_branch=$(git -C "$hint_dir" branch --show-current 2>/dev/null)
      hint_why="$hint_ahead commit(s) of its own${hint_branch:+ on $hint_branch}"
    elif [ -n "$(git -C "$hint_dir" status --porcelain 2>/dev/null)" ]; then
      hint_why="uncommitted changes"
    else
      echo "$hint_id is $hint_behind commit(s) behind its remote: run \`omarchy plugin update $hint_id\`, then this again" >&2
      continue
    fi
    echo "$hint_id is $hint_behind commit(s) behind its remote, and \`omarchy plugin update\` can't fast-forward it:" \
      "$hint_dir has $hint_why; bring it up to date by hand" >&2
  done
  return 0
}
