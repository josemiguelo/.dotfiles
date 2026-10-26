// Surfingkeys: Brave's vim-like keys, its settings in ~/.config/surfingkeys/surfingkeys.js.
package loadouts

import loadout.dsl.*

/**
 * Surfingkeys installed in Brave and allowed to read file URLs, so its
 * "Load settings from" can point at the deployed surfingkeys.js. Brave keeps
 * both in its own profile, so `install` only says what to do there.
 */
val surfingkeys = script(
    name = "surfingkeys",
    description = "Surfingkeys in Brave, reading ~/.config/surfingkeys/surfingkeys.js",
) {
    managedBy(".loadout/surfingkeys.sh")
    runAfter(brave)
}
