#!/usr/bin/env zsh
# Tests private_dot_config/zsh/plugins/repos/repos.plugin.zsh (gclone) in
# isolation: $HOME is a fixture inside a fresh mktemp directory (so ~/Repos is
# too), and git's url.<base>.insteadOf (in a throwaway global config) redirects
# the GitHub URLs to local repos, so clones are real but never touch the
# network. gum is the real binary except `confirm`, which needs a terminal: a
# stand-in answers it from $GCLONE_TEST_CONFIRM (yes/no).
#
# Safety: the script refuses to run unless its work directory is a fresh
# directory under the system temp dir, and every removal goes through
# fixture_rm, which refuses anything outside that directory. It never deletes
# a path built only from $HOME. Run: tests/test-repos-plugin.zsh

SCRIPT_DIR="${0:A:h}/.."
PLUGIN="$SCRIPT_DIR/private_dot_config/zsh/plugins/repos/repos.plugin.zsh"
REAL_HOME=$HOME

WORK="$(mktemp -d)" || exit 1
WORK=${WORK:A}
if [[ -z $WORK || $WORK != ${TMPDIR:-/tmp}/* || ! -d $WORK ]]; then
  print -u2 "refusing to run: work dir [$WORK] isn't a fresh temp directory"
  exit 1
fi

# Remove a path, only if it's inside $WORK.
fixture_rm() {
  local target=${1:A}
  if [[ -z $target || $target != $WORK/* ]]; then
    print -u2 "refusing to remove [$1]: outside the test directory $WORK"
    exit 1
  fi
  rm -rf -- "$target"
}

cleanup() {
  [[ -n $WORK && $WORK == ${TMPDIR:-/tmp}/* ]] && rm -rf -- "$WORK"
}
trap cleanup EXIT

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1" }
bad() { fail=$((fail + 1)); echo "  FAIL - $1" }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])" }

source "$PLUGIN"

echo "URL parsing"
parse() { local -a reply; _gclone_parse "$1" && print -r -- "$reply[2]/$reply[3]/$reply[4]" || print -r -- REJECTED }
eq "$(parse git@github.com:ai-hero-dev/ai-coding-crash-course.git)" gh/ai-hero-dev/ai-coding-crash-course "ssh scp-style, .git dropped"
eq "$(parse https://github.com/ai-hero-dev/ai-coding-crash-course)" gh/ai-hero-dev/ai-coding-crash-course "https"
eq "$(parse ssh://git@github.com:22/owner/repo.git)" gh/owner/repo "ssh:// with a port"
eq "$(parse https://github.com/owner/repo/tree/main/src)" gh/owner/repo "browser URL keeps owner/repo"
eq "$(parse https://github.com/owner/repo/)" gh/owner/repo "trailing slash"
eq "$(parse 'https://github.com/o/r?tab=readme')" gh/o/r "query string"
eq "$(parse https://WWW.GitHub.com/Owner/Repo.git)" gh/Owner/Repo "www. and host case; repo case kept"
eq "$(parse https://gitlab.com/group/sub/repo.git)" gl/sub/repo "GitLab subgroup keeps only sub/repo"
eq "$(parse https://gitlab.com/group/sub/repo/-/blob/main/README.md)" gl/sub/repo "GitLab page URL"
eq "$(parse https://bitbucket.org/team/repo/src/main/)" bb/team/repo "Bitbucket"
eq "$(parse https://codeberg.org/u/r.git)" cb/u/r "Codeberg"
eq "$(parse https://git.sr.ht/~user/tool)" srht/user/tool "sr.ht, ~ dropped"
eq "$(parse https://git.example.com/team/tool.git)" git.example.com/team/tool "unknown host keeps its name"
eq "$(parse https://github.com/onlyowner)" REJECTED "owner without repo rejected"
eq "$(parse notaurl)" REJECTED "not a URL rejected"
eq "$(parse https://github.com/../x)" REJECTED "dot segments rejected"

# From here on gclone runs for real, so $HOME moves into the fixture first.
export HOME="$WORK/home"
mkdir -p "$HOME"
if [[ $HOME == $REAL_HOME || $HOME != $WORK/* ]]; then
  print -u2 "refusing to run: HOME [$HOME] isn't inside the test directory"
  exit 1
fi
REPOS="$WORK/home/Repos"
TARGET="$REPOS/gh/acme/widget"

# Local repos the GitHub URLs are redirected to.
git init -q "$WORK/widget" && git -C "$WORK/widget" commit -q --allow-empty -m init
export GIT_CONFIG_GLOBAL="$WORK/gitconfig"
git config --global url."$WORK/widget".insteadOf "git@github.com:acme/widget.git"
git config --global --add url."$WORK/widget".insteadOf "https://github.com/acme/widget"
git config --global user.name test
git config --global user.email test@example.com

# gum stand-in: answers `confirm` from $GCLONE_TEST_CONFIRM, the rest is real.
FAKEBIN="$WORK/fakebin"
mkdir -p "$FAKEBIN"
REAL_GUM=${commands[gum]}
print -r -- '#!/bin/sh' > "$FAKEBIN/gum"
print -r -- 'if [ "$1" = confirm ]; then [ "$GCLONE_TEST_CONFIRM" = yes ]; exit; fi' >> "$FAKEBIN/gum"
print -r -- "exec \"$REAL_GUM\" \"\$@\"" >> "$FAKEBIN/gum"
chmod +x "$FAKEBIN/gum"
path=( "$FAKEBIN" $path )
hash -r

echo "cloning"
cd "$WORK"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 0 "clone succeeds"
eq "$PWD" "$TARGET" "cds into the new clone"
[[ -d $TARGET/.git ]] && ok "cloned under ~/Repos/gh/acme/widget" || bad "no clone at $TARGET"

echo "existing clone of the same repo"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone https://github.com/acme/widget >/dev/null 2>&1
eq "$?" 0 "same repo by another URL form: ok"
eq "$PWD" "$TARGET" "answering yes cds there"
cd "$WORK"
GCLONE_TEST_CONFIRM=no gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$WORK" "answering no stays put"

echo "folder holds another repo"
git -C "$TARGET" remote set-url origin https://github.com/someone/else.git
cd "$WORK"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 1 "a different repo there is an error"
eq "$(git -C "$TARGET" remote get-url origin)" https://github.com/someone/else.git "the other repo is left alone"
fixture_rm "$REPOS"

echo "folder isn't a repo"
mkdir -p "$TARGET" && touch "$TARGET/notes.txt"
gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$?" 1 "a non-empty non-repo folder is an error"
[[ -f $TARGET/notes.txt && ! -d $TARGET/.git ]] && ok "its files are left alone" || bad "folder was touched"
fixture_rm "$REPOS"

echo "bare repo already there"
mkdir -p "${TARGET:h}" && git clone -q --bare git@github.com:acme/widget.git "$TARGET"
cd "$WORK"
GCLONE_TEST_CONFIRM=yes gclone git@github.com:acme/widget.git >/dev/null 2>&1
eq "$PWD" "$TARGET" "a bare clone of the same repo counts as cloned"
fixture_rm "$REPOS"

echo "failed clone"
cd "$WORK"
gclone git@github.com:acme/missing.git >/dev/null 2>&1
eq "$?" 1 "clone of a missing repo fails"
[[ ! -e $REPOS ]] && ok "leaves no empty folders behind" || bad "left $(find "$REPOS")"
mkdir -p "$REPOS/gh/acme/keep"
gclone git@github.com:acme/missing.git >/dev/null 2>&1
[[ -d $REPOS/gh/acme/keep && ! -e $REPOS/gh/acme/missing ]] && ok "keeps folders it didn't create" || bad "removed or left the wrong folders"
fixture_rm "$REPOS"

echo "git clone options pass through"
cd "$WORK"
# A shallow clone needs a file:// URL; a plain path ignores --depth.
git config --global --unset-all url."$WORK/widget".insteadOf
git config --global protocol.file.allow always
git config --global url."file://$WORK/widget".insteadOf "git@github.com:acme/widget.git"
gclone git@github.com:acme/widget.git --depth 1 >/dev/null 2>&1
eq "$(git -C "$TARGET" rev-parse --is-shallow-repository 2>/dev/null)" true "--depth 1 reaches git clone"

echo "usage"
gclone >/dev/null 2>&1
eq "$?" 1 "no argument: usage, exit 1"
gclone --help >/dev/null 2>&1
eq "$?" 0 "--help: exit 0"
gclone notaurl >/dev/null 2>&1
eq "$?" 1 "not a URL: exit 1"

echo
echo "$pass passed, $fail failed"
(( fail == 0 ))
