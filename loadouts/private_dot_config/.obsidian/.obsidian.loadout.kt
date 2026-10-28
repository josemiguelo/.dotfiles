// Obsidian Sync without the app: Obsidian Headless (`ob`, a mise tool), the
// native binding it can't always fetch for itself, and the vault it syncs.
package loadouts

import loadout.dsl.*

object Obsidian {
    /** omalauncher: the native binding obsidian-headless's own install can't fetch there. */
    val headlessSqlite = script(
        name = "obsidian-headless-sqlite",
        description = "better-sqlite3's prebuilt binding for mise's obsidian-headless",
    ) {
        managedBy(".loadout/headless-sqlite.sh")
        runAfter(Mise.tools)
    }

    /** A vault synced into a folder, named by the machine: `run(Obsidian.sync, "<vault>", "<path>", "<mode>")`. */
    val sync = script(
        name = "obsidian-sync",
        description = "an Obsidian Sync vault in a local folder, through ob",
    ) {
        managedBy(".loadout/sync.sh")
        runAfter(Mise.tools, headlessSqlite)
    }
}

val obsidian = program(
    name = "obsidian",
    description = "Obsidian notes",
) {
    installVia(
        flatpak(pkg = "md.obsidian.Obsidian"),
        omarchy, // Omarchy preinstalls Arch's package and its launch flags
    )
}
