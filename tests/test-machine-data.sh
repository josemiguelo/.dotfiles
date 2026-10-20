#!/usr/bin/env bash
# Tests loadout's configs/.chezmoitemplates/loadout/machine partial under the
# real chezmoi, against a throwaway source: a copy of the partial (as
# `loadout compile` writes it) under a fixture .chezmoiroot, and a fixture
# .chezmoidata/loadout.json. Merging (defaults, profiles, the machine) is
# loadout's and tested there; this checks the partial picks the right table. HOME and the XDG dirs point inside one mktemp dir, so the real
# chezmoi binary only ever sees fixture config, state and files.
# Run: tests/test-machine-data.sh
set -u

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK="$(mktemp -d "${TMPDIR:-/tmp}/machine-data-test.XXXXXX")"

# Deletes only the dir this run created.
cleanup() {
  case "${WORK:?}" in
    "${TMPDIR:-/tmp}"/machine-data-test.*) rm -rf -- "${WORK:?}" ;;
    *) echo "refusing to delete $WORK" >&2 ;;
  esac
}
trap cleanup EXIT

export HOME="$WORK/home"
export XDG_CONFIG_HOME="$HOME/.config" XDG_CACHE_HOME="$HOME/.cache" XDG_DATA_HOME="$HOME/.local/share"
[[ "$HOME" == "$WORK"/* ]] || { echo "HOME is not inside the fixture" >&2; exit 1; }

SRC="$WORK/src"
mkdir -p "$HOME" "$SRC/configs/.chezmoitemplates/loadout" "$SRC/configs/.chezmoidata"
printf 'configs\n' > "$SRC/.chezmoiroot"
cp "$REPO/configs/.chezmoitemplates/loadout/machine" "$SRC/configs/.chezmoitemplates/loadout/" ||
  { echo "no loadout/machine partial: run loadout compile first" >&2; exit 1; }
# A real template using the partial, the way the dotfiles do.
printf '{{ if (includeTemplate "loadout/machine" . | fromJson).flag }}on{{ else }}off{{ end }}\n' > "$SRC/configs/dot_probe.tmpl"

cz() { chezmoi --source "$SRC" --destination "$HOME" --persistent-state "$WORK/state.boltdb" "$@"; }
HOST="$(cz execute-template '{{ .chezmoi.hostname }}')"
machine() { cz execute-template '{{ includeTemplate "loadout/machine" . }}'; }
# One value of the data, as JSON.
value() { cz execute-template "{{ index (includeTemplate \"loadout/machine\" . | fromJson) $1 | toJson }}"; }

# The data as loadout compile writes it: the defaults, and each machine's
# merged table. $1 = machines object.
data() {
  printf '{"loadout": {"defaults": {"flag": true, "color": "blue", "tags": ["a", "b"], "term": {"opacity": 0.85, "blur": 1}}, "machines": %s}}\n' "$1" > "$SRC/configs/.chezmoidata/loadout.json"
}

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

echo "a host the repo doesn't declare"
data '{"other": {"flag": false}}'
eq "$(machine)" '{"color":"blue","flag":true,"tags":["a","b"],"term":{"blur":1,"opacity":0.85}}' "gets the defaults"
eq "$(cz cat "$HOME/.probe")" "on" "a template sees the defaults"

echo "a declared host"
data "{\"$HOST\": {\"flag\": false, \"color\": \"red\", \"tags\": [\"a\", \"b\"], \"term\": {\"opacity\": 0.5, \"blur\": 1}}}"
eq "$(value '"flag"')" "false" "its false comes through"
eq "$(value '"color"')" '"red"' "its string comes through"
eq "$(value '"term"')" '{"blur":1,"opacity":0.5}' "its tables come through"
eq "$(cz cat "$HOME/.probe")" "off" "a template sees the machine's value"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
