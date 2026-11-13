import { custom, program } from "loadout";

export const ngrok = program("ngrok", {
  description: "ngrok tunnel",
  install: [custom({ installedBy: ".loadout/install-ngrok.ts" })],
  path: ["$HOME/.local/bin"],
  version: "ngrok version",
});
