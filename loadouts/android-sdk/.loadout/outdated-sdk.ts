// Custom `loadout machine outdated` oracle: is a pin in packages behind the newest
// stable package ON ITS OWN LINE? Only pins whose version is a number
// (build-tools;36.0.0, ndk;…, cmake;…), compared within their major:
// build-tools;36.0.0 against 36.x, never 37.x, since a new API level is a
// decision, not an update. platforms;android-36 and unversioned IDs
// (platform-tools) stay silent: Studio's own updates move those.
// Rows are `<item> <pin> <newest>`, the item being the ID before its version
// (build-tools); with several pins of one item, the first is the one compared.
//
// `update <item>` is the other half (loadout calls it per row): install the
// newest on that line and rewrite that pin in place, comments kept. The file
// is the repo's: commit the change afterwards.
import { existsSync } from "node:fs";
import type { OutdatedItem } from "loadout/script";
import { PINS, knownIds, pins, sdkDir, sdkmanagerInstall, sdkmanagerPath, studioJdk } from "#android-sdk";

const PRERELEASE = /(-rc|rc[0-9]|alpha|beta|preview)/i;

/** "<item> <version>" per numbered pin, the first of each item, in file order. */
async function numberedPins(): Promise<Map<string, string>> {
  const numbered = new Map<string, string>();
  for (const id of await pins()) {
    const parts = id.split(";");
    const version = parts.pop() ?? "";
    const item = parts.join(";");
    if (item && /^[0-9]/.test(version) && !numbered.has(item)) numbered.set(item, version);
  }
  return numbered;
}

/** Dotted versions compared number by number: 36.10.0 after 36.9.0. */
function compareVersions(a: string, b: string): number {
  const x = a.split(".").map(Number);
  const y = b.split(".").map(Number);
  for (let i = 0; i < Math.max(x.length, y.length); i++) {
    const diff = (x[i] ?? 0) - (y[i] ?? 0);
    if (diff !== 0) return diff;
  }
  return 0;
}

/** Newest stable version of item on pin's major line, "" when there's none. */
function newestInMajor(known: Set<string>, item: string, pin: string): string {
  const line = `${item};${pin.split(".")[0]}.`;
  return [...known]
    .filter((id) => id.startsWith(line) && !PRERELEASE.test(id))
    .map((id) => id.slice(item.length + 1))
    .sort(compareVersions)
    .at(-1) ?? "";
}

/** Swaps the first uncommented old ID in the pins file for new, the rest kept. */
async function repin(old: string, next: string) {
  const lines = (await Bun.file(PINS).text()).split("\n");
  const at = lines.findIndex((line) => line.replace(/#.*/, "").trim() === old);
  if (at < 0) throw new Error(`${old} isn't pinned in ${PINS}`);
  lines[at] = lines[at].replace(old, next);
  await Bun.write(PINS, lines.join("\n"));
}

/** The SDK, undefined where there's nothing to ask with. */
async function askable() {
  const sdk = await sdkDir();
  return sdk && existsSync(sdkmanagerPath(sdk)) && studioJdk() ? sdk : undefined;
}

export async function listOutdated() {
  const sdk = await askable();
  if (!sdk) return [];
  const known = await knownIds(sdk);
  const behind: OutdatedItem[] = [];
  for (const [item, pin] of await numberedPins()) {
    const newest = newestInMajor(known, item, pin);
    if (newest && newest !== pin) behind.push({ item, current: pin, candidate: newest });
  }
  return behind;
}

export async function update(item: string) {
  const sdk = await askable();
  if (!sdk) return;
  const known = await knownIds(sdk);
  const pin = (await numberedPins()).get(item);
  if (!pin) throw new Error(`no numbered pin for '${item}' in ${PINS}`);
  const newest = newestInMajor(known, item, pin);
  if (!newest) throw new Error(`sdkmanager lists nothing on ${pin.split(".")[0]}.x for '${item}'`);
  if (newest === pin) return console.log(`${item} already pinned to ${newest}`);
  await sdkmanagerInstall(sdk, [`${item};${newest}`]);
  await repin(`${item};${pin}`, `${item};${newest}`);
  console.log(`${item} pinned to ${newest} (was ${pin})`);
}
