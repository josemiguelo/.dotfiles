// VS Code: Omarchy's build (set up by ../.omarchy's omarchy-vscode).
import { omarchy, program, via } from "loadout";

export const code = program("code", {
  description: "Visual Studio Code",
  install: [
    // Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
    via(omarchy, { pkg: "visual-studio-code-bin" }),
  ],
});
