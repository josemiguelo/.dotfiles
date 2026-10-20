// A loadout config repo: `loadout compile` builds it into loadout.lock.json.
// The plugin and the DSL ship with loadout, in its share directory.
pluginManagement {
    val home = providers.environmentVariable("LOADOUT_HOME")
        .getOrElse("${System.getProperty("user.home")}/.local/share/loadout")
    val version = java.io.File("$home/VERSION").readText().trim()
    repositories {
        maven(uri("$home/maven"))
        gradlePluginPortal()
    }
    plugins {
        id("io.github.josemiguelo.loadout") version version
    }
}

rootProject.name = "jm-machines"
