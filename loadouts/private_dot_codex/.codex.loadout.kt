// Codex: OpenAI's CLI. Its global instructions are AGENTS.md, beside this
// file.
package loadouts

import loadout.dsl.*

/** OpenAI's Codex CLI: a cask on macOS; on Omarchy it comes from mise, so it isn't mapped there. */
val codex = program(
    name = "codex",
    description = "OpenAI Codex CLI",
) {
    installVia(
        brewCask,
    )
}
