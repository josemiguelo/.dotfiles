#!/usr/bin/env bun
// Omarchy's default coding agent (what its agent keybinding and menu open),
// set the native way, `omarchy default agent <name>`, without starting it:
// the agent is installed now, and set up (its login) the first time it's
// opened. On its own, the command ends by LAUNCHING the agent in a new
// terminal and, when the agent isn't installed yet, installs it in a floating
// one first: windows popping up in the middle of a setup. So the agent is
// installed here first (Omarchy declares it a lazy mise tool, so `mise
// install` is all it takes), and the command runs with a stand-in for
// `omarchy-agent`, its launcher, that does nothing. Everything else it does is
// its own: the setting, and for claude the browser extension.
// Commands run from $HOME: `omarchy default agent` runs `mise where`/`mise
// use -g`, and from the repo mise would also find the dotfiles' copy of its
// config in a parent and stop to ask whether to trust it.
// usage: default-agent.ts <agent>   (its mise tool shares its name)
import { chmod, mkdtemp, rm } from "node:fs/promises";
import { tmpdir } from "node:os";
import { $, ok, out, read, run } from "#loadout";

const HOME = process.env.HOME!;
const CONF = `${HOME}/.config/mise/config.toml`;

async function setDefault(agent?: string) {
  if (!agent) throw new Error("usage: default-agent.ts <agent>");
  const installed = () => ok($`mise where ${agent}`.cwd(HOME));
  if (!(await installed())) await $`mise install ${agent}`.cwd(HOME);
  if (!(await installed())) throw new Error(`${agent} didn't install through mise`);

  // The command may run `mise use -g <agent>`, writing the agent into the
  // dotfiles' config.toml; conf.d/omarchy.toml already lists it, so
  // config.toml goes back to what it was.
  const saved = await read(CONF);
  const quiet = await mkdtemp(`${tmpdir()}/default-agent-`);
  try {
    await Bun.write(`${quiet}/omarchy-agent`, "#!/bin/sh\nexit 0\n");
    await chmod(`${quiet}/omarchy-agent`, 0o755);
    await $`omarchy default agent ${agent}`.cwd(HOME).env({ ...process.env, PATH: `${quiet}:${process.env.PATH}` });
  } finally {
    if (saved) await Bun.write(CONF, saved);
    await rm(quiet, { recursive: true, force: true });
  }
  if ((await out($`omarchy default agent`.cwd(HOME))) !== agent) throw new Error(`the default agent is still not ${agent}`);
  console.log(`${agent} is Omarchy's default agent; it sets itself up the first time it's opened`);
}

await run(setDefault);
