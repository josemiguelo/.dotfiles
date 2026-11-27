// jm's machines: programs, scripts, machines and dotfiles in one repo.
// Each tool is a folder in loadouts/: its manifest, its scripts, and its
// dotfiles, home/ for $HOME and root/ for /. Compile builds chezmoi's sources
// from them (.chezmoi-home, which .chezmoiroot names, and .chezmoi-root).
import { include, repo } from "loadout";
import { schema } from "./machines/data.ts";

// Every tool's fragments, then the machines and their profiles. A new
// fragment needs no import here.
await include("loadouts/*/*.loadout.ts", "machines/**/*.loadout.ts");

repo({
  name: "jm's machines",
  stateFolder: "machines/state",
  dotfiles: { tools: "loadouts/*", home: ".chezmoi-home", root: ".chezmoi-root" },
  minLoadoutVersion: "1.0.0",
  data: schema,
});
