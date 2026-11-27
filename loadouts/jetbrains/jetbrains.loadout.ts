// JetBrains: the Toolbox app (it installs into ~/.local/share/JetBrains) and
// its launchers on PATH. IdeaVim's config is home/dot_ideavimrc.
import { program, script, withBrewCask, withCustomSteps } from "loadout";

export const jetbrainsToolbox = program("jetbrains-toolbox", {
  description: "JetBrains Toolbox",
  canWait: "an app download; nothing in setup needs it",
  canBeInstalled: [
    // Linux: per-user install from JetBrains' release feed (the script says
    // why not the ublue-os cask). Version = the build.txt Toolbox ships.
    withCustomSteps("linux", { module: () => import("./.loadout/install-toolbox.ts"), versionRegex: /([0-9]+\.[0-9][0-9.]*)/ }),
    withBrewCask({ keepUnused: "for macOS; no Mac installs it yet" }),
  ],
});

export const linkJetbrainsLaunchersLinux = script("link-jetbrains-launchers-linux", {
  description: "symlink JetBrains Toolbox launcher scripts into ~/.local/bin",
  canWait: "runs after the Toolbox, which can wait",
  module: () => import("./.loadout/link-launchers.ts"),
  runAfter: [jetbrainsToolbox],
});
