// An Omarchy web app (its own app window), installed with Omarchy's own
// omarchy-webapp-install: one module per app, exporting what webapp() gives.
import { $, read } from "loadout/script";

export type WebApp = {
  /** The launcher's name: ~/.local/share/applications/<name>.desktop. */
  name: string;
  url: string;
  icon: string;
  /** What the launcher's Exec line must open, as a regex: the app's host. */
  host: RegExp;
};

/** app's check and install: done when its launcher opens its host. */
export function webapp(app: WebApp) {
  const desktop = `${process.env.HOME}/.local/share/applications/${app.name}.desktop`;
  const exec = new RegExp(`^Exec=omarchy-launch-webapp.*${app.host.source}`, "m");
  const check = async () => exec.test(await read(desktop));
  async function install() {
    await $`omarchy-webapp-install ${app.name} ${app.url} ${app.icon}`;
    if (!(await check())) throw new Error(`${app.name} web app not in place after install`);
  }
  return { check, install };
}
