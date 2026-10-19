#!/bin/sh
# Tests maintenance/lib/main-checkout.sh against a real repo and a real
# worktree of it, both inside a fresh mktemp directory. Run:
# tests/test-main-checkout.sh

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
. "$ROOT/maintenance/lib/main-checkout.sh"

WORK=$(mktemp -d) || exit 1
WORK=$(cd "$WORK" && pwd -P)
trap 'rm -rf -- "$WORK"' EXIT

pass=0
fail=0
eq() {
  if [ "$1" = "$2" ]; then pass=$((pass + 1)); echo "  ok - $3"
  else fail=$((fail + 1)); echo "  FAIL - $3 (expected [$2], got [$1])"; fi
}

export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
git init -q "$WORK/main"
mkdir -p "$WORK/main/a/b"
echo x > "$WORK/main/a/b/s.sh"
git -C "$WORK/main" add . && git -C "$WORK/main" -c user.name=t -c user.email=t@t commit -q -m init
git -C "$WORK/main" worktree add -q "$WORK/wt/feature" -b feature
echo y > "$WORK/wt/feature/a/new.sh"
mkdir -p "$WORK/plain"
echo z > "$WORK/plain/s.sh"

echo "main_checkout_path"
eq "$(main_checkout_path "$WORK/main/a/b/s.sh")" "$WORK/main/a/b/s.sh" "in the main checkout: its own path"
eq "$(main_checkout_path "$WORK/wt/feature/a/b/s.sh")" "$WORK/main/a/b/s.sh" "in a worktree: the main checkout's copy"
eq "$(main_checkout_path "$WORK/wt/feature/a/b/../b/s.sh")" "$WORK/main/a/b/s.sh" "a path with .. resolves"
eq "$(main_checkout_path "$WORK/wt/feature/a/new.sh")" "$WORK/wt/feature/a/new.sh" "new to the worktree: its own path"
eq "$(main_checkout_path "$WORK/plain/s.sh")" "$WORK/plain/s.sh" "outside a repo: its own path"
eq "$(cd "$WORK/wt/feature/a" && main_checkout_path b/s.sh)" "$WORK/main/a/b/s.sh" "a relative path"

echo
echo "$pass passed, $fail failed"
[ "$fail" -eq 0 ]
