#!/usr/bin/env bun
// Linux: no tpack, tmux or git from brew. The tpack cask pulled in brew's tmux
// and git, which brew's bin put ahead of the system's on PATH: a tmux server of
// another version than the one Omarchy's own launches run, and another git.
// tpack now comes from its release (install-tpack.sh), so this removes the
// cask, then tmux and git unless another brew package still needs them (that
// one is reported and left alone: removing it would break the other).
// Modes: `check` / `install` (default).
import { accessSync, constants } from "node:fs";
import { brew, brewPrefix, main, ok } from "#loadout";

const FORMULAE = ["tmux", "git"];
const prefix = await brewPrefix();

/** Without brew there's nothing to remove. */
const hasBrew = () => {
  try {
    accessSync(`${prefix}/bin/brew`, constants.X_OK);
    return true;
  } catch {
    return false;
  }
};

const hasCask = () => ok(brew("list", "--cask", "tpack"));
const hasFormula = (f: string) => ok(brew("list", "--formula", f));
/** The installed brew packages that need f. */
const usersOf = async (f: string) =>
  (await brew("uses", "--installed", f).quiet().nothrow()).stdout.toString().split(/\s+/).filter(Boolean);

async function clean() {
  if (!hasBrew()) return true;
  let done = true;
  if (await hasCask()) {
    console.log("brew has the tpack cask");
    done = false;
  }
  for (const f of FORMULAE) {
    if ((await hasFormula(f)) && (await usersOf(f)).length === 0) {
      console.log(`brew has ${f}`);
      done = false;
    }
  }
  return done;
}

async function install() {
  if (!hasBrew()) return;
  if (await hasCask()) await brew("uninstall", "--cask", "tpack");
  for (const f of FORMULAE) {
    if (!(await hasFormula(f))) continue;
    const users = await usersOf(f);
    if (users.length > 0) console.error(`keeping brew's ${f}: needed by ${users.join(" ")}`);
    else await brew("uninstall", "--formula", f);
  }
}

await main(clean, install);
