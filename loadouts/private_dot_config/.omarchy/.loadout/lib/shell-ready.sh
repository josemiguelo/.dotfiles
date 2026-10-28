# Sourced by the scripts that talk to the Omarchy shell over IPC (omarchy-shell,
# and `omarchy plugin …`, which goes through it). omarchy-shell gives each call
# OMARCHY_SHELL_IPC_TIMEOUT, 2s by default, and the shell can take longer while
# it hot-reloads plugins or restarts — omarchy-bar-icons restarts it after
# rebuilding widgets — so a script run right after reads "omarchy-shell is not
# responding", or a plugin as not enabled. Calls get 10s here, and
# shell_ready waits (up to 30s) until the shell answers at all.

export OMARCHY_SHELL_IPC_TIMEOUT=${OMARCHY_SHELL_IPC_TIMEOUT:-10s}

shell_ready() {
  tries=0
  until omarchy-shell shell ping >/dev/null 2>&1; do
    tries=$((tries + 1))
    [ "$tries" -lt 30 ] || { echo "omarchy-shell isn't answering" >&2; return 1; }
    sleep 1
  done
}
