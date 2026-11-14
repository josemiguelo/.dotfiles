import { custom, program, script } from "loadout";

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

// The buns an earlier loadout downloaded for the scripts. loadout is its own
// bun now, so the folder only takes space; its wrapper lives in bin/, beside
// it, and stays.
export const removeLoadoutBunDownloads = script("remove-loadout-bun-downloads", {
  description: "no bun downloads of an earlier loadout (loadout is its own bun)",
  run: 'rm -rf "${XDG_DATA_HOME:-$HOME/.local/share}/loadout/bun"',
  check: 'test ! -e "${XDG_DATA_HOME:-$HOME/.local/share}/loadout/bun"',
  transitional: true,
});
