// jm's machines: programs, scripts, machines and dotfiles in one repo.
// chezmoi reads loadouts/ (.chezmoiroot); its templates read each machine's
// merged data from loadout.lock.json.
import { include, repo } from "loadout";
import { schema } from "./machines/data.ts";

// Every tool's fragment, where the tool lands in loadouts/ (or in
// .etc/<concern>/ for what lands outside $HOME), then the machines and their
// profiles. A new fragment needs no import here.
await include("loadouts/**/*.loadout.ts", "machines/**/*.loadout.ts");

repo({
  name: "jm's machines",
  state: "machines/state",
  configs: "loadouts",
  minToolVersion: "5.0.0",
  data: schema,
});
