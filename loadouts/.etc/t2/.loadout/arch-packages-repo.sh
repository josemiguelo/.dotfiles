#!/bin/sh
# The [t2-arch-packages] pacman repo: KaiT2en's T2 drivers and tools packaged
# for linux-omarchy (github.com/josemiguelo/t2-arch-packages), signed with
# FPR below (t2-arch-packages.asc, beside this script).
#
# Omarchy's installer adds the repo on T2 Macs (the t2-kait2en branch's
# install/hardware/pacman.sh), but `omarchy refresh pacman` and channel
# switches rewrite /etc/pacman.conf from Omarchy's channel template, without
# it. They run ~/.config/omarchy/hooks/pre-refresh-pacman.d/* right after, so
# a hook there puts it back. pacman-conf follows Includes, so the repo counts
# whether pacman.conf names it itself or includes a file that does (another
# hook's /etc/pacman.d/custom-repos.conf); either way it is never added twice.
#
# check: the repo is configured, its key is trusted (locally signed or
# populated from t2-arch-packages-keyring), and the hook is in place.
# install: whichever of those is missing.
# Modes: `check` / `install` (default).
set -eu

REPO=t2-arch-packages
SERVER=https://github.com/josemiguelo/t2-arch-packages/releases/download/repo
FPR=077D8295CCF834D3F5EC25F70506B72C34EB162F
HERE="$(cd "$(dirname "$0")" && pwd)"
KEY=$HERE/t2-arch-packages.asc
HOOK=${XDG_CONFIG_HOME:-$HOME/.config}/omarchy/hooks/pre-refresh-pacman.d/t2-arch-packages

hook_text() {
  cat <<HOOK_EOF
#!/bin/bash
# Managed by loadout (t2-arch-packages-repo): \`omarchy refresh pacman\` just
# rewrote /etc/pacman.conf from Omarchy's channel template; put the signed
# [$REPO] repo back, unless something already configures it.
pacman-conf --repo-list 2>/dev/null | grep -qx $REPO && exit 0
printf '\n[%s]\nServer = %s\n' $REPO $SERVER | sudo tee -a /etc/pacman.conf >/dev/null
HOOK_EOF
}

repo_ready() {
  pacman-conf --repo-list 2>/dev/null | grep -qx "$REPO"
}

# pacman-key lists the key unprivileged; trusted means full or ultimate validity.
key_ready() {
  pacman-key --list-keys "$FPR" 2>/dev/null | grep -q -E '^uid +\[ *(full|ultimate) *\]'
}

hook_ready() {
  [ -x "$HOOK" ] && [ "$(cat "$HOOK")" = "$(hook_text)" ]
}

case "${1:-install}" in
check)
  repo_ready && key_ready && hook_ready
  ;;
install)
  if ! key_ready; then
    sudo pacman-key --add "$KEY"
    sudo pacman-key --lsign-key "$FPR"
  fi
  if ! repo_ready; then
    printf '\n[%s]\nServer = %s\n' "$REPO" "$SERVER" | sudo tee -a /etc/pacman.conf >/dev/null
  fi
  if ! hook_ready; then
    mkdir -p "$(dirname "$HOOK")"
    hook_text > "$HOOK"
    chmod 755 "$HOOK"
  fi
  repo_ready || { echo "pacman doesn't list [$REPO] after install" >&2; exit 1; }
  key_ready || { echo "pacman doesn't trust $FPR after install" >&2; exit 1; }
  hook_ready || { echo "$HOOK not in place after install" >&2; exit 1; }
  ;;
*) echo "usage: $0 [check|install]" >&2; exit 2 ;;
esac
