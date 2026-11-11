#!/usr/bin/env bun
// The systemd user manager's environment reflects ~/.config/environment.d.
// The manager reads those files only when it starts or on daemon-reload, so a
// file the dotfiles just wrote is invisible to the session (and everything
// it launches) until one of those happens — and a logout does not restart
// the manager while anything (a tmux server, say) keeps it alive.
// Modes: `check` (every KEY=VALUE assignment present in the manager env?) /
// `install` (daemon-reload, then the same test).
import { existsSync, readdirSync } from "node:fs";
import { $, main, out, read } from "#loadout";

const ENV_D = `${process.env.HOME}/.config/environment.d`;

/** The assignments the .conf files make (comments and blank lines aren't). */
async function wanted() {
  if (!existsSync(ENV_D)) return [];
  const confs = readdirSync(ENV_D).filter((f) => f.endsWith(".conf")).sort();
  const lines = (await Promise.all(confs.map((f) => read(`${ENV_D}/${f}`)))).flatMap((t) => t.split("\n"));
  return lines.filter((l) => /^[A-Za-z_][A-Za-z0-9_]*=/.test(l));
}

async function missing() {
  const current = new Set((await out($`systemctl --user show-environment`)).split("\n"));
  return (await wanted()).filter((l) => !current.has(l));
}

await main(
  async () => (await missing()).length === 0,
  async () => {
    if ((await missing()).length > 0) await $`systemctl --user daemon-reload`;
    const left = await missing();
    if (left.length > 0) throw new Error(`still not in the user manager environment:\n${left.join("\n")}`);
  },
);
