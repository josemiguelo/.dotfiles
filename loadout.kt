// jm's machines: programs, scripts, machines and dotfiles in one repo.
// chezmoi reads configs/ (.chezmoiroot); its templates read each machine's
// merged data from loadout.lock.json.
package loadouts

import loadout.dsl.*

val loadout = repo(name = "jm's machines", state = "state", configs = "configs", minToolVersion = "3.3.0", data = ::Data)

/** Every per-machine setting, with its default. Dotfile templates branch on these, not on hostnames. */
class Data : MachineData() {
    /** An Omarchy machine (Linuxbrew reaches the shell from the zsh config). */
    var omarchy by flag(false)

    /** The work machine: work-only tools in, personal ones (e.g. Copilot) out; the rest comes from its private child repo. */
    var work by flag(false)

    /** Arch inside the omalauncher Android launcher: only the launcher's configs deploy, and no desktop's reach it. */
    var omalauncher by flag(false)

    val kitty by table(::Kitty)

    class Kitty : MachineData() {
        /** background_opacity; Omarchy's scratchpad repaints its own windows on top. */
        var opacity by number(0.85)
    }
}

/** The repo's one-liner, so machine files say `data { work = true }`. */
fun MachineScope.data(block: Data.() -> Unit) = data(::Data, block)

// The built-in installers this repo uses, as names every file sees. brew and
// brew-cask are the repo's own (configs/private_dot_config/.homebrew), replacing the built-ins.
val dnf = Builtin.dnf
val dnfRepo = Builtin.dnfRepo
val dnfCopr = Builtin.dnfCopr
val flatpak = Builtin.flatpak
val omarchy = Builtin.omarchy
val omarchyAur = Builtin.omarchyAur
val pacman = Builtin.pacman
