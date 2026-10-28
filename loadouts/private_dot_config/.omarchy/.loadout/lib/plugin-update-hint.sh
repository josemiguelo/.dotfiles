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

# plugin_diverged <dir>: why `omarchy plugin update` can't fast-forward the
# checkout in <dir> to its remote's HEAD ("N commit(s) of its own on
# <branch>", "uncommitted changes"), or nothing when it can. Reads
# FETCH_HEAD, so it comes right after a `git fetch origin HEAD` there.
plugin_diverged() {
  div_ahead=$(git -C "$1" rev-list --count FETCH_HEAD..HEAD 2>/dev/null) || div_ahead=0
  if [ "$div_ahead" -gt 0 ]; then
    div_branch=$(git -C "$1" branch --show-current 2>/dev/null)
    echo "$div_ahead commit(s) of its own${div_branch:+ on $div_branch}"
  elif [ -n "$(git -C "$1" status --porcelain 2>/dev/null)" ]; then
    echo "uncommitted changes"
  fi
}

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
    hint_why=$(plugin_diverged "$hint_dir")
    if [ -z "$hint_why" ]; then
      echo "$hint_id is $hint_behind commit(s) behind its remote: run \`omarchy plugin update $hint_id\`, then this again" >&2
    else
      echo "$hint_id is $hint_behind commit(s) behind its remote, and \`omarchy plugin update\` can't fast-forward it:" \
        "$hint_dir has $hint_why; bring it up to date by hand" >&2
    fi
  done
  return 0
}
