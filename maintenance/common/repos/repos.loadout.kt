// josemiguelo's repos, cloned where start-dotfiles-change's sessions expect them.
package loadouts

import loadout.dsl.*

/** Bare clones with their default branch's worktree, named by the machine: `run(bareRepos, "loadout", "loadout.wiki")`. */
val bareRepos = script(
    name = "bare-repos",
    description = "josemiguelo's repos as bare clones in ~/Repos/gh/josemiguelo",
) {
    managedBy("bare-repos.sh")
    runAfter(git)
}
