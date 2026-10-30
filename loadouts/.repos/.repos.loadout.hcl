# josemiguelo's repos, cloned where start-dotfiles-change's sessions expect them.

# Bare clones with their default branch's worktree, named by the machine:
# `args(script.bare-repos, "loadout", "loadout.wiki")`.
script "bare-repos" {
  description = "josemiguelo's repos as bare clones in ~/Repos/gh/josemiguelo"
  managed_by  = ".loadout/bare-repos.sh"
  run_after   = [program.git]
}
