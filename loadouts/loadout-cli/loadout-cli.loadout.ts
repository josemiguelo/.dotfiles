import { program, script, withCustomSteps } from "loadout";

// Its release, into ~/.local; `loadout machine sync` and `self upgrade` keep it
// current.
export const loadout = program("loadout", {
  description: "loadout, which reads this repo",
  canBeInstalled: [
    withCustomSteps({
        installCommand: "curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh",
      }),
  ],
  searchPath: ["$HOME/.local/bin"],
  versionCommand: "loadout --version",
  keepUnused: "bootstrap.sh installs loadout on every machine; this is for one that lists it",
});

