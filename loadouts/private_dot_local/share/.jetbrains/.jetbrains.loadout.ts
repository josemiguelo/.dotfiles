// JetBrains: the Toolbox app (it installs into ~/.local/share/JetBrains) and
// its launchers on PATH. IdeaVim's config is loadouts/dot_ideavimrc.
import { brewCask, custom, program, script, via } from "loadout";

export const jetbrainsToolbox = program("jetbrains-toolbox", {
  description: "JetBrains Toolbox",
  install: [
    // Linux: per-user install from JetBrains' release feed (the script says
    // why not the ublue-os cask). Version = the build.txt Toolbox ships.
    custom("linux", { managedBy: ".loadout/install-toolbox.ts", regex: "([0-9]+\\.[0-9][0-9.]*)" }),
    via(brewCask, { spare: "for macOS; no Mac installs it yet" }),
  ],
});

export const linkJetbrainsLaunchersLinux = script("link-jetbrains-launchers-linux", {
  description: "symlink JetBrains Toolbox launcher scripts into ~/.local/bin",
  managedBy: ".loadout/link-launchers.ts",
  runAfter: [jetbrainsToolbox],
});
