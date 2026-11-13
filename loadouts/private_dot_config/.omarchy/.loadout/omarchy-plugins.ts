#!/usr/bin/env bun
// Omarchy shell plugins from git, named by URL in the machine's opt-in (one
// per line in a multi-line entry), each added and enabled with Omarchy's own
// `omarchy plugin add --enable`. A plugin is matched to its URL by its
// checkout's origin under ~/.config/omarchy/plugins (the folder is named by
// the plugin's id, not its URL). Done = every URL installed and enabled.
// Plugins run unsandboxed inside the shell: list only ones you trust.
// usage: omarchy-plugins.ts [check] <git-url>...
import { $, fail, main } from "loadout/script";
import { SHELL_JSON, pluginCheckouts, pluginUpdateHint, readJson, shellReady, widgetEnabled } from "#omarchy";

function urls(args: string[]) {
  if (args.length === 0) fail("usage: omarchy-plugins.ts [check] <git-url>...");
  return args;
}

/** A URL without a trailing slash or .git, so both spellings match. */
const normalize = (url: string) => url.replace(/\/*$/, "").replace(/\.git$/, "");

/** The plugin checkout cloned from url, or null. */
async function pluginDir(url: string) {
  for (const dir of pluginCheckouts()) {
    const origin = await $`git -C ${dir} config --get remote.origin.url`.quiet().nothrow();
    if (origin.exitCode === 0 && normalize(origin.stdout.toString().trim()) === normalize(url)) return dir;
  }
  return null;
}

const pluginId = async (dir: string): Promise<string> => (await readJson(`${dir}/manifest.json`))?.id;

/**
 * Enabled as `omarchy plugin list` says, or by an entry in shell.json's
 * plugins[]: the list only counts a bar widget that is on the bar, while the
 * shell also loads one listed there (Keystroke's menu, while its bar button
 * is off the bar).
 */
async function enabled(id: string) {
  if (await widgetEnabled(id)) return true;
  const shell = await readJson(SHELL_JSON);
  return (shell?.plugins ?? []).some((p: any) => p?.id === id) && !(shell?.disabledPlugins ?? []).includes(id);
}

/** The URLs not yet installed and enabled. */
async function pending(args: string[]) {
  const left: string[] = [];
  for (const url of urls(args)) {
    const dir = await pluginDir(url);
    if (!dir || !(await enabled(await pluginId(dir)))) left.push(url);
  }
  return left;
}

async function check(...args: string[]) {
  await shellReady("check");
  const left = await pending(args);
  if (left.length) console.log(`not installed and enabled: ${left.join(" ")}`);
  return left.length === 0;
}

async function install(...args: string[]) {
  await shellReady();
  for (const url of await pending(args)) {
    // Each plugin added reloads the shell; the next waits for it.
    await shellReady();
    const dir = await pluginDir(url);
    if (dir) await $`omarchy plugin enable ${await pluginId(dir)}`;
    else await $`omarchy plugin add ${url} --enable --yes`;
  }
  const left = await pending(args);
  if (left.length === 0) return;
  console.error(`not installed and enabled: ${left.join(" ")}`);
  // One installed but not enabled may have failed Omarchy's validation with
  // a version the shell has outgrown.
  for (const url of left) {
    const dir = await pluginDir(url);
    if (dir) await pluginUpdateHint(await pluginId(dir));
  }
  process.exit(1);
}

await main(check, install);
