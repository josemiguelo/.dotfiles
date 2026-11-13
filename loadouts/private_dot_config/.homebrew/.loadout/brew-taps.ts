#!/usr/bin/env bun
// Taps one third-party Homebrew tap and trusts it, for this user. Trust is per
// user (~/.homebrew/trust.json), so a tap another account trusted still fails
// here with "Refusing to load ... from untrusted tap". Each tap is declared by
// the program that installs from it, in that program's own fragment, so this
// script takes the tap as an argument and knows no list of its own.
//
//   brew-taps.ts check <tap>                    exit 0 when the tap is tapped and trusted
//   brew-taps.ts install <tap>                  tap and trust it (a no-op when it already is)
//   brew-taps.ts install <tap> <name> [--cask]  then install <name> (its full path) from it
import { main } from "loadout/script";
import { brew } from "#brew";

function usage(): never {
  console.error("usage: brew-taps.ts check <tap> | install <tap> [<name> [--cask]]");
  process.exit(2);
}

/** brew tap-info's lines; its stderr dropped, and a failure reads as no lines. */
const tapInfo = async (tap: string) => (await brew("tap-info", tap).quiet().nothrow()).stdout.toString().split("\n");

const trusted = async (tap: string) => (await tapInfo(tap)).includes("Trusted");

async function install(tap: string, name?: string, kind?: string) {
  if (!(await tapInfo(tap)).some((line) => line.includes("Installed"))) await brew("tap", tap);
  if (!(await trusted(tap))) await brew("trust", "--tap", tap);
  if (name === undefined) return;
  if (kind === "--cask") await brew("install", "--cask", name);
  else await brew("install", name);
}

const argv = Bun.argv.slice(2);
if (argv.length < 2 || argv.length > 4 || (argv[0] !== "check" && argv[0] !== "install")) usage();
await main(trusted, install);
