// VS Code, set up by Omarchy's own installer (omarchy-install-editor-vscode):
// Omarchy's build (visual-studio-code-bin), libsecret for its keyring,
// VS Code's self-update turned off (pacman updates it), and Omarchy's theme.
// The installer WRITES ~/.config/Code/User/settings.json (update.mode only)
// and opens VS Code when it's done — the check keeps that to the first run.
import { $, succeeds, read } from "loadout/script";

const ARGV = `${process.env.HOME}/.vscode/argv.json`;

export const check = async () => (await succeeds($`pacman -Q visual-studio-code-bin`)) && (await read(ARGV)).includes("gnome-libsecret");

export async function install() {
  await $`omarchy-install-editor-vscode`;
  if (!(await check())) throw new Error("VS Code isn't fully set up");
}
