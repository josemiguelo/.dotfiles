#!/bin/sh
# Every package the launcher's files declare (`requires { pacman: [...] }` in
# the top-level widgets/*.owl: widgets, faces, apps, panels, the key bar)
# installed. The files are the record of what they need, so no widget's
# packages are listed anywhere else; the launcher's own "install" button on a
# tile installs them too, and this still sees whether they're there.
# Modes: `check` / `install` (default).
set -eu

DIR="$HOME/.config/omalauncher/widgets"

# One package per line, from every requires block (one may span lines).
declared() {
  for f in "$DIR"/*.owl; do
    [ -f "$f" ] || continue
    tr '\n' ' ' <"$f" | grep -o 'requires *{[^}]*}' | grep -o 'pacman *: *\[[^]]*\]' | grep -o '"[^"]*"' | tr -d '"'
  done | sort -u
}

# What pacman doesn't have installed (-T prints the missing ones).
missing() {
  pkgs=$(declared)
  [ -n "$pkgs" ] || return 0
  # shellcheck disable=SC2086 # one word per package
  pacman -T $pkgs || true
}

case "${1:-install}" in
check)
  out=$(missing)
  [ -z "$out" ] && exit 0
  printf 'missing: %s\n' $out
  exit 1
  ;;
install)
  out=$(missing)
  # shellcheck disable=SC2086
  [ -z "$out" ] || sudo pacman -S --needed --noconfirm $out
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
