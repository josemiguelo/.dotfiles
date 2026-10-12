#!/bin/sh
# This machine's ssh key (setup-ssh's, named by the opt-in) on the GitHub
# account, titled with the machine's name, so pushes over ssh work: setup-ssh
# makes a new key on every fresh install and nothing else tells GitHub about
# it. Nothing in setup needs it (public repos are fetched over https); pushing
# does.
#
# Install logs gh in when it isn't (`gh auth login --web`: a one-time code to
# approve in the browser, the only manual step of a new machine), adds the key,
# and deletes any older key with the same title: a previous install of this
# machine. Keys with other titles are never touched.
#
# gh comes from wherever the machine has it: PATH, mise's shims (Omarchy's
# conf.d/omarchy.toml installs it through mise) or Homebrew's prefix (the gh
# program, macOS). $HOME is the cwd: from the repo, mise would find the
# dotfiles' copy of its config and ask to trust it.
# The check only asks GitHub over ssh whether the key authenticates.
# usage: github-ssh-key.sh [check] <key-name>
set -eu

MODE=install
if [ "${1:-}" = check ]; then MODE=check; shift; fi
KEY=$HOME/.ssh/${1:?usage: $0 [check] <key-name>}
TITLE=${LOADOUT_MACHINE:-$(hostname -s)}
. "$LOADOUT_REPO/configs/private_dot_local/lib/brew-prefix.sh"
cd "$HOME"
export PATH="$PATH:${MISE_DATA_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/mise}/shims:$BREW_PREFIX/bin"

authenticates() {
  ssh -T -i "$KEY" -o IdentitiesOnly=yes -o BatchMode=yes -o ConnectTimeout=10 git@github.com 2>&1 |
    grep -q "successfully authenticated"
}

case "$MODE" in
check)
  authenticates
  ;;
install)
  [ -f "$KEY.pub" ] || { echo "no $KEY.pub: setup-ssh makes it" >&2; exit 1; }
  authenticates && exit 0
  command -v gh >/dev/null 2>&1 ||
    { echo "gh isn't installed: map the gh program for this machine (Omarchy: mise-tools installs it)" >&2; exit 1; }
  if ! gh auth status -h github.com >/dev/null 2>&1; then
    gh auth login -h github.com --web --git-protocol ssh --skip-ssh-key -s admin:public_key
  elif ! gh auth status -h github.com 2>&1 | grep -q "admin:public_key"; then
    gh auth refresh -h github.com -s admin:public_key
  fi
  mine=$(cut -d' ' -f2 "$KEY.pub")
  gh api user/keys --paginate --jq '.[] | "\(.id)\t\(.title)\t\(.key)"' |
    while IFS="$(printf '\t')" read -r id title key; do
      [ "$title" = "$TITLE" ] || continue
      case "$key" in *"$mine"*) continue ;; esac
      gh ssh-key delete "$id" --yes
      echo "deleted $TITLE's previous key (id $id)"
    done
  if ! gh api user/keys --paginate --jq '.[].key' | grep -qF -- "$mine"; then
    gh ssh-key add "$KEY.pub" --title "$TITLE"
  fi
  authenticates || { echo "GitHub still refuses $KEY over ssh" >&2; exit 1; }
  echo "GitHub knows $KEY as \"$TITLE\""
  ;;
esac
