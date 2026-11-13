import { custom, program } from "loadout";

// Its release, into ~/.local; `loadout sync` and `self-upgrade` keep it
// current.
export const loadout = program("loadout", {
  description: "loadout, which reads this repo",
  install: [
    custom({
        command: "curl -fsSL https://raw.githubusercontent.com/josemiguelo/loadout/master/install.sh | sh",
      }),
  ],
  path: ["$HOME/.local/bin"],
  version: "loadout --version",
  spare: "bootstrap.sh installs loadout on every machine; this is for one that lists it",
});
