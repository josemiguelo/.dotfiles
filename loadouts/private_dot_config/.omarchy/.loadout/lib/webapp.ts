// An Omarchy web app (its own app window), installed with Omarchy's own
// omarchy-webapp-install: one script per app, each a call to webapp().
import { $, main, read } from "#loadout";

export type WebApp = {
  /** The launcher's name: ~/.local/share/applications/<name>.desktop. */
  name: string;
  url: string;
  icon: string;
  /** What the launcher's Exec line must open, as a regex: the app's host. */
  host: RegExp;
};

/** Runs the managed_by protocol for app: done when its launcher opens its host. */
export async function webapp(app: WebApp) {
  const desktop = `${process.env.HOME}/.local/share/applications/${app.name}.desktop`;
  const exec = new RegExp(`^Exec=omarchy-launch-webapp.*${app.host.source}`, "m");
  const ready = async () => exec.test(await read(desktop));
  await main(ready, async () => {
    await $`omarchy-webapp-install ${app.name} ${app.url} ${app.icon}`;
    if (!(await ready())) throw new Error(`${app.name} web app not in place after install`);
  });
}
