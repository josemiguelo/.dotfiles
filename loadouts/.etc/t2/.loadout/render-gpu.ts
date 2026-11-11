#!/usr/bin/env bun
// Hyprland renders on the GPU that drives the built-in panel.
//
// The MacBookPro16,1 has an Intel iGPU and an AMD dGPU, and the Apple gmux
// wires the panel (eDP) to one of them: the AMD one, as the machine boots.
// Hyprland (aquamarine) takes the first DRM card it enumerates as its primary
// renderer, which is the Intel one, so every frame — the cursor's included —
// was drawn on Intel and copied across to the AMD card for scanout. The
// cursor lagged and typing felt slow; the Hyprland log said "gpu
// /dev/dri/card1 becomes primary drm" (i915) while eDP-1 hung off card2
// (amdgpu). AQ_DRM_DEVICES names the primary.
//
// Nothing here names a card or a PCI address: card numbers follow probe order,
// and the gmux can put the panel on either GPU (force_igd). The block finds,
// at every login, the card whose eDP connector is connected, and leaves
// AQ_DRM_DEVICES unset when there's none. It lives in
// ~/.config/uwsm/env-hyprland, which uwsm sources before starting Hyprland —
// Hyprland's own config is read after aquamarine has picked its GPU. Only
// the panel's card is listed: the Thunderbolt ports are wired to the AMD card
// too. Install rewrites the block between its markers; takes effect at the
// next login. Modes: `check` / `install` (default).
import { mkdirSync } from "node:fs";
import { dirname } from "node:path";
import { $, main, read } from "#loadout";

const ENV_FILE = `${process.env.XDG_CONFIG_HOME || `${process.env.HOME}/.config`}/uwsm/env-hyprland`;
const BEGIN = "# >>> Managed by loadout (t2-render-gpu)";
const END = "# <<< Managed by loadout (t2-render-gpu)";
const BLOCK = `# >>> Managed by loadout (t2-render-gpu)
# Hyprland renders on the GPU the built-in panel is wired to, picked at login
# (loadouts/.etc/t2/.loadout/render-gpu.ts): left alone it renders on the Intel iGPU and
# copies every frame to the AMD card driving the panel, which lags.
for status in /sys/class/drm/card*-eDP-*/status; do
  [ "$(cat "$status" 2>/dev/null)" = connected ] || continue
  card=\${status#/sys/class/drm/}
  export AQ_DRM_DEVICES="/dev/dri/\${card%%-*}"
  break
done
unset status card
# <<< Managed by loadout (t2-render-gpu)`;

/** The file's lines, split into the block (markers included) and the rest. */
async function parts() {
  const block: string[] = [];
  const rest: string[] = [];
  let on = false;
  for (const line of (await read(ENV_FILE)).split("\n")) {
    if (line === BEGIN) on = true;
    (on ? block : rest).push(line);
    if (line === END) on = false;
  }
  return { block: block.join("\n"), rest: rest.join("\n").replace(/\n+$/, "") };
}

/** The block, exactly, between its markers. */
const ready = async () => (await parts()).block === BLOCK;

async function install() {
  if (!(await ready())) {
    mkdirSync(dirname(ENV_FILE), { recursive: true });
    const { rest } = await parts();
    await Bun.write(ENV_FILE, `${rest ? `${rest}\n\n` : ""}${BLOCK}\n`);
  }
  if (!(await ready())) throw new Error(`${ENV_FILE} doesn't hold the block after install`);
  const device = (await $`env -i sh -c ${`. '${ENV_FILE}'; echo "\${AQ_DRM_DEVICES:-}"`}`.quiet().text()).trim();
  if (device) console.log(`Hyprland renders on ${device} from the next login.`);
  else console.error("No connected built-in panel found; Hyprland keeps its own choice.");
}

await main(ready, install);
