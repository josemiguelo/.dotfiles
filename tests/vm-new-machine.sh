#!/usr/bin/env bash
# A new machine from nothing, in a VM, unattended: Omarchy installed from its
# ISO into a base image (omarchy-iso's bin/omarchy-iso-test --install-only,
# made once and reused), a throwaway overlay of it booted, served loadout and
# these dotfiles from this machine (built from their checkouts, nothing
# published), and set up as omarchy-vm with `loadout machine new`, run
# twice: a step that only works once a later one has run fails in the first
# pass and passes in the second.
#
# The steps that need the owner's accounts (1Password's app, GitHub's and
# atuin's logins) fail at once instead of waiting; everything else runs. With
# --desktop the VM logs into its desktop first (SDDM's autologin, in the
# throwaway overlay), so what talks to Hyprland, the Omarchy shell or the
# session's D-Bus runs as it does on a real machine.
#
# With --manual nothing runs by itself: the VM opens in a window here, logged
# into its desktop, and its terminal (Super+Enter) runs the real bootstrap.sh
# with `bash <(curl -fsSL 10.0.2.2:8123/go)`, which asks what a new machine
# asks (sudo's password is omarchy) and waits for the logins it needs. The VM
# stops when its window is closed.
#
#   tests/vm-new-machine.sh [--desktop | --manual] <omarchy iso> [<run dir>]
#
# The run dir (default ~/.cache/vm-new-machine: the overlay grows to tens of
# GB as the VM installs, more than a /tmp in memory holds) gets the served files, the
# overlay and the logs: setup.log and setup-again.log (each pass's output),
# check.log (`loadout script check --all` at the end) and status.log. Needs KVM,
# omarchy-iso's checkout and its dependencies (qemu-full, socat, tesseract).
set -euo pipefail

DESKTOP=false
MANUAL=false
case "${1:-}" in
  --desktop) DESKTOP=true; shift ;;
  --manual) DESKTOP=true; MANUAL=true; shift ;;
esac
ISO=$(realpath "${1:?usage: tests/vm-new-machine.sh [--desktop | --manual] <omarchy iso> [<run dir>]}")
RUN=${2:-${XDG_CACHE_HOME:-$HOME/.cache}/vm-new-machine}
DOTFILES=$(cd "$(dirname "$0")/.." && pwd)
LOADOUT=${LOADOUT_CHECKOUT:-$HOME/Repos/gh/josemiguelo/loadout/all_worktrees/master}
OMARCHY_ISO=${OMARCHY_ISO_CHECKOUT:-$HOME/Repos/gh/josemiguelo/omarchy-iso/all_worktrees/quattro}
BASE_DIR=$OMARCHY_ISO/test-runs/$(basename "$ISO" .iso)
PORT=8123
SSH_PORT=2222
H=http://10.0.2.2:$PORT
VERSION=v$(sed -n 's/^export const VERSION = "\(.*\)";$/\1/p' "$LOADOUT/src/version.ts")
say() { printf '\n==> %s (%s)\n' "$*" "$(date +%H:%M:%S)"; }

if [ -f "$BASE_DIR/base.qcow2" ]; then
  say "base image: $BASE_DIR"
else
  say "installing $(basename "$ISO") into a base image, unattended"
  (cd "$OMARCHY_ISO" && bin/omarchy-iso-test "$ISO" --install-only --no-preview)
fi

rm -rf "$RUN" && mkdir -p "$RUN/serve/$VERSION"
say "serving loadout $VERSION ($LOADOUT) and the dotfiles' $(git -C "$DOTFILES" branch --show-current) at $(git -C "$DOTFILES" rev-parse --short HEAD), committed work only"
(cd "$LOADOUT" && bun run build >/dev/null 2>&1)
tar -C "$LOADOUT/build" -czf "$RUN/serve/$VERSION/loadout-$VERSION-linux-x64.tar.gz" loadout
cp "$LOADOUT/install.sh" "$RUN/serve/"
git clone --quiet --bare --branch "$(git -C "$DOTFILES" branch --show-current)" "$DOTFILES" "$RUN/serve/dotfiles.git"
git -C "$RUN/serve/dotfiles.git" update-server-info
# bootstrap.sh as it is in this checkout, and what runs it with everything
# from here: `bash <(curl -fsSL 10.0.2.2:8123/go)` in the VM.
cp "$DOTFILES/bootstrap.sh" "$RUN/serve/"
# script(1) keeps it a terminal for bootstrap's prompts (and loadout's live
# view), and records what the terminal shows in ~/vm-setup.log: bootstrap's
# own steps as text, loadout's as the view's redraws. loadout's run log
# (~/.local/state/loadout/runs/) has each step's whole output as plain text.
cat >"$RUN/serve/go" <<GO
script -q -e -c 'curl -fsSL $H/bootstrap.sh | BOOTSTRAP_DOTFILES=$H/dotfiles.git BOOTSTRAP_RAW=$H/raw BOOTSTRAP_LOADOUT_INSTALL=$H/install.sh LOADOUT_VERSION=$VERSION LOADOUT_DOWNLOAD_BASE=$H sh -s -- omarchy-vm' ~/vm-setup.log
GO
mkdir -p "$RUN/serve/raw"
git -C "$DOTFILES" show HEAD:loadout.lock.json >"$RUN/serve/raw/loadout.lock.json"
python3 -m http.server --bind 127.0.0.1 --directory "$RUN/serve" "$PORT" >"$RUN/serve.log" 2>&1 &
SERVER=$!

if $MANUAL; then
  DISPLAY_ARGS=(-display gtk,zoom-to-fit=on)
  say "booting a throwaway overlay of the base, in a window"
else
  DISPLAY_ARGS=(-display none -vnc 127.0.0.1:5)
  say "booting a throwaway overlay of the base (its screen: vncviewer -RemoteResize=0 127.0.0.1:5905)"
fi
qemu-img create -q -f qcow2 -b "$BASE_DIR/base.qcow2" -F qcow2 "$RUN/run.qcow2"
cp "$BASE_DIR/OVMF_VARS.4m.fd" "$RUN/"
qemu-system-x86_64 \
  -cpu host -enable-kvm -machine q35,accel=kvm -smp "$(nproc)" -m 8192 \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/edk2/x64/OVMF_CODE.4m.fd \
  -drive if=pflash,format=raw,file="$RUN/OVMF_VARS.4m.fd" \
  -drive file="$RUN/run.qcow2",format=qcow2,if=none,id=drive0 -device virtio-blk-pci,drive=drive0,bootindex=1 \
  -device virtio-vga "${DISPLAY_ARGS[@]}" -usb -device usb-tablet \
  -netdev user,id=net0,hostfwd=tcp:127.0.0.1:$SSH_PORT-:22 -device virtio-net-pci,netdev=net0 \
  -pidfile "$RUN/qemu.pid" -daemonize
trap 'kill $SERVER 2>/dev/null; kill "$(cat "$RUN/qemu.pid" 2>/dev/null)" 2>/dev/null || true' EXIT
vm() {
  ssh -i "$BASE_DIR/id_ed25519" -p "$SSH_PORT" -o BatchMode=yes -o IdentitiesOnly=yes -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -o LogLevel=ERROR -o ServerAliveInterval=30 omarchy@127.0.0.1 "$@"
}
# Omarchy's environment (OMARCHY_PATH) comes with a login shell, which a
# plain ssh command doesn't start; its commands refuse to run without it.
vml() { vm "bash -lc $(printf '%q' "$1")"; }
for _ in $(seq 1 100); do vm true 2>/dev/null && break; sleep 3; done
vm true

if ! $MANUAL; then
  say "sudo without a password (a throwaway VM)"
  vm "echo omarchy | sudo -S -p '' sh -c 'echo \"omarchy ALL=(ALL) NOPASSWD: ALL\" > /etc/sudoers.d/90-loadout-test && chmod 440 /etc/sudoers.d/90-loadout-test'"
fi

if $DESKTOP; then
  say "logging into the desktop (SDDM's autologin)"
  vm 'session=$(ls /usr/share/wayland-sessions/ | grep -m1 uwsm || ls /usr/share/wayland-sessions/ | head -n 1)
    echo omarchy | sudo -S -p "" sh -c "printf \"[Autologin]\\nUser=omarchy\\nSession=%s\\n\" ${session%.desktop} >/etc/sddm.conf.d/90-loadout-test.conf && systemctl restart sddm"'
  for _ in $(seq 1 60); do vml "omarchy-shell shell ping" >/dev/null 2>&1 && break; sleep 3; done
  vml "omarchy-shell shell ping" >/dev/null || { echo "the desktop didn't come up: look at the VM's screen" >&2; exit 1; }
fi

if $MANUAL; then
  cat <<EOF

The VM is in its window, logged into its desktop. In its terminal (Super+Enter):

  bash <(curl -fsSL 10.0.2.2:$PORT/go)

That's bootstrap.sh, with loadout and the dotfiles from here: it asks for
sudo's password (omarchy) and waits for the logins it needs, as on a real
machine. loadout's part ends naming its run log (~/.local/state/loadout/runs/
in the VM: every step's whole output, as plain text, to read over ssh);
~/vm-setup.log has what the terminal showed. Its key goes on your GitHub
account as "omarchy-vm": delete it
there when you're done. The VM stops when you close its window.
EOF
  while kill -0 "$(cat "$RUN/qemu.pid")" 2>/dev/null; do sleep 5; done
  exit 0
fi

# bootstrap.sh's own steps, without its terminal (`bootstrap.sh --dry-run`
# shows them): the hostname, the dotfiles, loadout.
say "the hostname, the dotfiles and loadout, as bootstrap.sh does"
vml "set -e
  sudo hostnamectl set-hostname omarchy-vm
  [ -s /var/lib/pacman/sync/core.db ] || omarchy update -y
  command -v chezmoi >/dev/null || omarchy pkg add chezmoi
  chezmoi init --apply $H/dotfiles.git
  git -C ~/.local/share/chezmoi config core.hooksPath .githooks
  curl -fsSL $H/install.sh | LOADOUT_VERSION=$VERSION LOADOUT_DOWNLOAD_BASE=$H sh
  ~/.local/bin/loadout --version" >"$RUN/bootstrap.log" 2>&1

loadout_vm() {
  vml "export PATH=\$HOME/.local/bin:\$PATH LOADOUT_REPO=\$HOME/.local/share/chezmoi
    export MISE_IGNORED_CONFIG_PATHS=\$HOME/.local/share/chezmoi:\$HOME/.local/share/chezmoi__worktrees
    export ONEPASSWORD_WAIT=0 ATUIN_LOGIN_WAIT=0 OP_UNLOCK_WAIT=0 OBSIDIAN_WAIT=0
    loadout --repo \$LOADOUT_REPO --machine omarchy-vm $1 </dev/null"
}
for pass in setup setup-again; do
  say "loadout machine new --yes ($pass)"
  loadout_vm "machine new --yes" >"$RUN/$pass.log" 2>&1 && echo "  exit 0" || echo "  exit $?"
  tail -n 3 "$RUN/$pass.log" | sed 's/\x1b\[[0-9;]*m//g'
done
loadout_vm "script check --all" >"$RUN/check.log" 2>&1 || true
loadout_vm "machine status --no-write" >"$RUN/status.log" 2>&1 || true
say "done: $RUN"
