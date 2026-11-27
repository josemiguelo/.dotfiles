// antidote and its bundles, exactly as $ZDOTDIR/.zplugins declares them.
// antidote keeps no lockfile, so the check is presence: antidote itself is
// cloned, and every owner/repo bundle has a clone. Whether a clone is behind
// its remote is the antidote / antidote-plugins oracles' question.
import { existsSync } from "node:fs";
import { $, isOnPath } from "loadout/script";
import { ANTIDOTE, BUNDLES, bundleAll, bundlePaths } from "#antidote";

export async function check() {
  if (!existsSync(BUNDLES)) throw new Error(".zplugins not found");
  // Without antidote there's nothing to ask about its bundles.
  if (!existsSync(`${ANTIDOTE}/.git`)) {
    console.log(`missing: antidote itself (${ANTIDOTE})`);
    return false;
  }
  const missing = (await bundlePaths()).filter(({ dir }) => !dir);
  for (const { repo } of missing) console.log(`missing bundle: ${repo}`);
  return missing.length === 0;
}

export async function install() {
  if (!isOnPath("zsh")) throw new Error("zsh not found");
  if (!existsSync(`${ANTIDOTE}/.git`)) {
    await $`git clone --depth 1 --quiet https://github.com/mattmc3/antidote ${ANTIDOTE}`;
  }
  await bundleAll();
}
