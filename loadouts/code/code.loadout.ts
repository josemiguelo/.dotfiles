// VS Code: Omarchy's build, set up by Omarchy's installer (omarchy-vscode).
import { program, script, withOmarchy } from "loadout";

export const code = program("code", {
  description: "Visual Studio Code",
  canBeInstalled: [
    // Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
    withOmarchy({ packageName: "visual-studio-code-bin" }),
  ],
});

// Omarchy's installer (keyring, no self-update, its theme); overwrites
// settings.json and opens VS Code once.
export const omarchyVscode = script("omarchy-vscode", {
  description: "VS Code, set up by Omarchy's installer",
  module: () => import("./.loadout/omarchy-vscode.ts"),
  runAfter: [code],
});
