# From its author's tap.
program "workmux" {
  description = "git worktrees + tmux windows for parallel agent sessions"
  depends_on  = [program.tmux]

  via "brew-tap" {
    params = { tap = "raine/workmux" }
  }
}

# Reruns after every workmux upgrade, since one can change the hooks or
# skills.
script "workmux-setup" {
  description = "workmux's status-tracking hooks and skills for the agents here"
  managed_by  = ".loadout/setup.sh"
  run_after   = [program.workmux]
}
