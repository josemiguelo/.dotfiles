// Slack: Slack's repo on Fedora (.loadout/slack.repo), the AUR elsewhere.
package loadouts

import loadout.dsl.*

val slack = program(
    name = "slack",
    description = "Slack desktop app",
) {
    installVia(
        dnfRepo(repofile = file(".loadout/slack.repo")),
        omarchyAur(pkg = "slack-desktop"), // Slack's own build, repackaged
    )
}
