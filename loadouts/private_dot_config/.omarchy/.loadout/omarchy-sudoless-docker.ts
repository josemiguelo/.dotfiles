#!/usr/bin/env bun
// Sudoless Docker, Omarchy's opt-in: the user in the docker group, so docker,
// lazydocker and the Docker TUI reach the daemon without a polkit/sudo prompt.
// The docker group is root-equivalent (the daemon runs as root: `docker run
// -v /:/host …` is the whole disk), which is why Omarchy leaves users out of
// it and asks first. This runs what omarchy-setup-security-sudoless-docker
// runs once you confirm — its confirmations need a terminal loadout's pane
// doesn't have — and asks Omarchy's own omarchy-sudo-docker whether it's
// configured. Group membership is read when a session starts, so it takes a
// reboot; like Omarchy, install marks reboot-required (omarchy update's
// restart step reads it). An Omarchy migration once took users out of the
// group; the check catches that happening again.
// Modes: `check` / `install` (default).
import { $, has, main, ok } from "#loadout";

/** omarchy-sudo-docker --configured succeeds when Docker would still need sudo. */
async function configured() {
  if (!has("omarchy-sudo-docker")) throw new Error("omarchy-sudo-docker not found");
  return !(await ok($`omarchy-sudo-docker --configured`));
}

async function install() {
  if (!(await configured())) {
    await $`sudo usermod -aG docker ${process.env.USER!}`;
    await $`omarchy-state set reboot-required`;
  }
  if (!(await configured())) throw new Error(`${process.env.USER} still isn't in the docker group`);
  if (await ok($`omarchy-sudo-docker`)) console.log("Sudoless Docker is configured; it takes effect after a reboot.");
}

await main(configured, install);
