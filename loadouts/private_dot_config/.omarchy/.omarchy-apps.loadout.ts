// Apps set up the Omarchy way. The apps themselves are programs; the
// scripts import .loadout/lib/.
import { script } from "loadout";
import { n1passwordCli, onePassword } from "../.1password/.1password.loadout.ts";
import { brave } from "../.brave.loadout.ts";
import { code } from "../.code/.code.loadout.ts";
import { lazydocker } from "../.lazydocker.loadout.ts";

// Omarchy's own setup of apps the machine installs, the omarchy-<app>
// scripts: `run: [omarchyBrave]`; the app is `brave`.

// Omarchy's installer (Chromium extension entry), started unscaled at login,
// Ctrl+Shift+Space for Quick Access.
export const omarchy1password = script("omarchy-1password", {
  description: "1Password via Omarchy's installer, unscaled, Ctrl+Shift+Space Quick Access",
  managedBy: ".loadout/omarchy-1password.ts",
  needsSudo: true,
  runAfter: [onePassword, n1passwordCli],
});

export const omarchyBrave = script("omarchy-brave", {
  description: "Brave, set up by Omarchy's browser installer",
  managedBy: ".loadout/omarchy-brave.ts",
  needsSudo: true,
  runAfter: [brave],
});

// What Surfingkeys left in Brave's flags: the split view extension's entry on
// the --load-extension line (its files go through .chezmoiremove).
export const removeSurfingkeys = script("remove-surfingkeys", {
  description: "no Surfingkeys split view extension on Brave's --load-extension line",
  managedBy: ".loadout/remove-surfingkeys.ts",
  runAfter: [omarchyBrave],
  transitional: true,
});

// The default browser, named by the machine:
// `args(omarchyDefaultBrowser, "brave")`.
export const omarchyDefaultBrowser = script("omarchy-default-browser", {
  description: "Omarchy's default browser",
  file: ".loadout/omarchy-default-browser-arch.ts",
  check: 'test "$(omarchy default browser)" = "$1"',
  runAfter: [brave, omarchyBrave],
});

// Superwhisper as the dictation backend Omarchy's keys (Alt+Space, Right Alt)
// run, set by Omarchy's own installer, unattended (--background): it installs
// superwhisper-bin when missing (Omarchy 4.5 ships it, but a machine upgraded
// from before may not have it), runs its per-user setup and makes it the
// backend. What a fresh 4.5 install's first run does.
export const omarchyDefaultDictation = script("omarchy-default-dictation", {
  description: "Superwhisper as Omarchy's dictation backend",
  run: "omarchy-install-dictation-superwhisper --background",
  check: 'test "$(omarchy default dictation 2>/dev/null)" = superwhisper',
  needsSudo: true,
});

// What this repo added around Voxtype, Omarchy's dictation backend here before
// Superwhisper: its bar plugin and settings TUI. Voxtype itself stays as
// Omarchy's installer left it.
export const omarchyRemoveVoxtypeExtras = script("omarchy-remove-voxtype-extras", {
  description: "no Voxtype bar plugin or settings TUI (stock Voxtype stays)",
  run: "omarchy plugin remove io.github.zeus-deus.voxtype --yes; omarchy-pkg-drop voxtype-tui",
  check: '! pacman -Q voxtype-tui >/dev/null 2>&1 && test ! -e "$HOME/.config/omarchy/plugins/io.github.zeus-deus.voxtype"',
  needsSudo: true,
  runAfter: [omarchyDefaultDictation],
  transitional: true,
});

// Omarchy's installer (keyring, no self-update, its theme); overwrites
// settings.json and opens VS Code once.
export const omarchyVscode = script("omarchy-vscode", {
  description: "VS Code, set up by Omarchy's installer",
  managedBy: ".loadout/omarchy-vscode.ts",
  runAfter: [code],
});

// docker group membership: root-equivalent, so opted into per machine.
export const omarchySudolessDocker = script("omarchy-sudoless-docker", {
  description: "sudoless Docker (user in the docker group)",
  managedBy: ".loadout/omarchy-sudoless-docker.ts",
  needsSudo: true,
  runAfter: [lazydocker],
});

// Omarchy's agent launchers (~/.local/bin) and seeded configs (~/.config),
// pruned to the agents the machine names.
export const omarchyAgentsPrune = script("omarchy-agents-prune", {
  description: "only the Omarchy agent launchers and configs in use",
  managedBy: ".loadout/omarchy-agents-prune.ts",
});
