#!/usr/bin/env bash
# Tests configs/.chezmoitemplates/machine (and machine-layer, merge-data)
# against a throwaway source: copies of the partials under a fixture
# .chezmoiroot, a fixture loadout.yaml, profiles/ and machines/<hostname>.yaml for this
# host. HOME and the XDG dirs point inside one mktemp dir, so the real
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
mkdir -p "$HOME" "$SRC/configs/.chezmoitemplates" "$SRC/machines" "$SRC/profiles"
printf 'configs\n' > "$SRC/.chezmoiroot"
for partial in machine machine-layer merge-data; do
  cp "$REPO/configs/.chezmoitemplates/$partial" "$SRC/configs/.chezmoitemplates/"
done
# A real template using the partial, the way the dotfiles do.
printf '{{ if (includeTemplate "machine" . | fromJson).flag }}on{{ else }}off{{ end }}\n' > "$SRC/configs/dot_probe.tmpl"
printf 'data:\n  flag: true\n  color: blue\n  tags: [a, b]\n  term:\n    opacity: 0.85\n    blur: 1\n' > "$SRC/loadout.yaml"

cz() { chezmoi --source "$SRC" --destination "$HOME" --persistent-state "$WORK/state.boltdb" "$@"; }
HOST="$(cz execute-template '{{ .chezmoi.hostname }}')"
machine() { cz execute-template '{{ includeTemplate "machine" . }}'; }
# One value of the merged data, as JSON.
value() { cz execute-template "{{ index (includeTemplate \"machine\" . | fromJson) $1 | toJson }}"; }

pass=0
fail=0
ok() { pass=$((pass + 1)); echo "  ok - $1"; }
bad() { fail=$((fail + 1)); echo "  FAIL - $1"; }
eq() { [[ "$1" == "$2" ]] && ok "$3" || bad "$3 (expected [$2], got [$1])"; }

echo "no machine file for this host"
eq "$(machine)" '{"color":"blue","flag":true,"tags":["a","b"],"term":{"blur":1,"opacity":0.85}}' "gets loadout.yaml's defaults"
eq "$(cz cat "$HOME/.probe")" "on" "a template sees the defaults"

echo "a machine file of its own"
printf 'data:\n  flag: false\n  color: red\n' > "$SRC/machines/$HOST.yaml"
eq "$(value '"flag"')" "false" "its false overrides a true default"
eq "$(value '"color"')" '"red"' "its string overrides the default"
eq "$(value '"tags"')" '["a","b"]' "keys it doesn't set keep their defaults"
eq "$(cz cat "$HOME/.probe")" "off" "a template sees the machine's value"

echo "a profile extending a profile"
printf 'data:\n  flag: false\n  tags: [x]\n  term:\n    blur: 0\n' > "$SRC/profiles/root.yaml"
printf 'extends: [root]\n\ndata:\n  color: green\n' > "$SRC/profiles/mid.yaml"
printf 'extends: [mid]\n\ndata:\n  flag: true\n  term:\n    opacity: 0.99\n' > "$SRC/machines/$HOST.yaml"
eq "$(value '"flag"')" "true" "the machine wins over its profiles"
eq "$(value '"color"')" '"green"' "the nearer profile's value comes through"
eq "$(value '"tags"')" '["x"]' "a profile's list replaces the default's"
eq "$(value '"term"')" '{"blur":0,"opacity":0.99}' "tables merge key by key across the chain"

echo "several profiles and group data"
printf 'data:\n  color: green\n' > "$SRC/profiles/look.yaml"
printf 'data:\n  term:\n    blur: 5\n' > "$SRC/profiles/glass.yaml"
printf 'extends: [look, glass]\n\nterm:\n  install_with: x\n\ndata:\n  term:\n    opacity: 0.5\n' > "$SRC/machines/$HOST.yaml"
eq "$(value '"color"')" '"green"' "one profile of the list sets its key"
eq "$(value '"term"')" '{"blur":5,"opacity":0.5}' "a program's data is data.<program>, from a profile and from the machine"
eq "$(value '"flag"')" "true" "keys no file sets keep their defaults"

echo
echo "$pass passed, $fail failed"
[[ "$fail" -eq 0 ]]
