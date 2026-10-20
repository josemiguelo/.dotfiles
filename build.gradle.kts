// The config repo as a Gradle project: the IDE gets completion and
// go-to-definition, and `loadout compile` writes loadout.lock.json. Only
// authoring needs a JDK; a fresh machine reads the committed lock.
plugins {
    id("io.github.josemiguelo.loadout")
}

// The manifest files, in compile order (loadout's glob rules: dot-files
// match only when the glob spells the dot).
loadout {
    sources(
        "loadout.kt",
        "programs/**/*.loadout.kt",
        "maintenance/**/*.loadout.kt",
        "configs/**/.*.loadout.kt",
        "machines/**/*.loadout.kt",
    )
}
