# op_unlocked <who>: the 1Password CLI lets this script read, asking in the
# open when it has to. Sourced by the steps that read secrets with `op`
# (intentional-sync, kait2en-dev, t2-bcm-firmware) and by onepassword-cli.
#
# A locked app, or a CLI not yet approved this session, makes `op` wait on a
# prompt in the 1Password app. With its output thrown away, that wait looked
# like a hang: onepassword-cli approves it on its first run, but on a later
# run its check passes and it's skipped, so the prompt came up behind a
# silenced `op vault list`. So: a quick silent try first (already approved:
# nothing shown), then the wait announced, op's own messages on screen, for
# up to OP_UNLOCK_WAIT seconds (default 120).
op_unlocked() {
  _ou_who=${1:-1password}
  _ou_t=$(command -v timeout 2>/dev/null || true)
  if [ -n "$_ou_t" ]; then
    "$_ou_t" 5 op vault list >/dev/null 2>&1 && return 0
  fi
  echo "$_ou_who: waiting for 1Password: unlock the app and approve its prompt…" >&2
  if [ -n "$_ou_t" ]; then
    "$_ou_t" "${OP_UNLOCK_WAIT:-120}" op vault list >/dev/null && return 0
  else
    op vault list >/dev/null && return 0
  fi
  echo "$_ou_who: 1Password didn't let the CLI in (still locked, the prompt was denied, or no answer in ${OP_UNLOCK_WAIT:-120}s); run this again once it's unlocked" >&2
  return 1
}
