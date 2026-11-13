# josemiguelo's repos, cloned where start-dotfiles-change's sessions expect them.

# Bare clones with their default branch's worktree, named by the machine:
# `args(script.bare-repos, "loadout", "loadout.wiki")`.
script "bare-repos" {
  description = "josemiguelo's repos as bare clones in ~/Repos/gh/josemiguelo"
  managed_by  = ".loadout/bare-repos.ts"
  run_after   = [program.git]
}

# The KaiT2en -> Omarchy work (docs/t2-macbook.md), on top of bare-repos'
# t2-arch-packages, omarchy and omarchy-iso: the forks' T2 worktrees (omarchy's
# t2-kait2en-stable, omarchy-iso's t2-kait2en)
# and upstream remotes, KaiT2en and omarchy-pkgs, libvfio-user built, the
# package signing key from 1Password, and kait2en-sync's daily timer.
script "kait2en-dev" {
  description = "KaiT2en -> Omarchy development: forks, clones, signing key, daily kait2en-sync"
  managed_by  = ".loadout/kait2en-dev.ts"
  run_after   = [
    script.bare-repos, script.onepassword-cli,
    program.meson, program.ninja, program.json-c, program.cmocka,
  ]
}
