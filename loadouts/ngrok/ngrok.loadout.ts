import { program, withCustomSteps } from "loadout";

export const ngrok = program("ngrok", {
  description: "ngrok tunnel",
  canBeInstalled: [withCustomSteps({ module: () => import("./.loadout/install-ngrok.ts"), versionCommand: "ngrok version" })],
  searchPath: ["$HOME/.local/bin"],
});
