#!/usr/bin/env bun
// SSH access to this machine, set up the native way:
// omarchy-setup-security-sshd enables sshd, opens 22/tcp in ufw (rate
// limited, comment "omarchy-sshd"), authorizes a key and then turns password
// logins off (sshd_config.d/10-omarchy-hardening.conf). Its rule opens 22 to
// any address, so after it the rule is narrowed to the private IPv4 ranges:
// a LAN, a VM's bridge, not the internet (a café's Wi-Fi is private too, so
// the keys are still what keeps others out). It authorizes one key
// per call, so it runs once per trusted key this machine doesn't trust yet.
// Trusted are the keys of the GitHub account gh is logged in to whose titles
// are named (github-ssh-key titles a machine's key with the machine's name),
// not all of them: a key added to the account later, by a new machine or by
// someone else, gets no shell here until it's named.
// ~/.ssh/authorized_keys mirrors them: a key deleted on GitHub, or no longer
// named, loses access here on the next run. GitHub serves keys without their
// comments, so no email ends up in authorized_keys.
// The check reads only world-readable files and asks gh, so `loadout status`
// needs no sudo for it.
// usage: omarchy-sshd.ts [check] <key-title>...
import { existsSync, writeFileSync } from "node:fs";
import { $, main, read } from "#loadout";

const HOME = process.env.HOME!;
// gh from mise's shims, where Omarchy's conf.d/omarchy.toml installs it.
const PATH = `${process.env.MISE_DATA_DIR || `${process.env.XDG_DATA_HOME || `${HOME}/.local/share`}/mise`}/shims:${process.env.PATH}`;
const AUTHORIZED_KEYS = `${HOME}/.ssh/authorized_keys`;
const HARDENING = "/etc/ssh/sshd_config.d/10-omarchy-hardening.conf";
const RULES = "/etc/ufw/user.rules";
const RULES6 = "/etc/ufw/user6.rules";
const PRIVATE = ["10.0.0.0/8", "172.16.0.0/12", "192.168.0.0/16"];
const HEX = Buffer.from("omarchy-sshd").toString("hex");
const KEY = /^(ssh|ecdsa|sk-)/;

const usage = () => new Error("usage: omarchy-sshd.ts [check] <key-title>...");
/** "type base64": the part of a key that identifies it. */
const ident = (key: string) => key.trim().split(/\s+/).slice(0, 2).join(" ");

/** The trusted keys (by title), sorted, one ident each. */
async function githubKeys(titles: string[]) {
  const all = await $`gh api user/keys --paginate --jq ${'.[] | "\\(.title)\t\\(.key)"'}`.env({ ...process.env, PATH }).quiet().nothrow();
  if (all.exitCode !== 0) throw new Error("could not list the account's keys (gh api user/keys)");
  const keys = new Set<string>();
  for (const line of all.stdout.toString().split("\n")) {
    const [title, key] = line.split("\t");
    if (key && titles.includes(title) && key.trim().split(/\s+/).length >= 2) keys.add(ident(key));
  }
  if (keys.size === 0) throw new Error(`none of the trusted keys is on GitHub: ${titles.join(" ")}`);
  return [...keys].sort();
}

const authorized = async () =>
  [...new Set((await read(AUTHORIZED_KEYS)).split("\n").filter((l) => KEY.test(l)).map(ident))].sort();

/** 22 open from each private range, and from nowhere else (Omarchy's rule, from any address, IPv6's included). */
async function firewallScoped() {
  const rules = (await read(RULES)).split("\n");
  const rules6 = (await read(RULES6)).split("\n");
  const scoped = PRIVATE.every((range) => rules.includes(`### tuple ### limit tcp 22 0.0.0.0/0 any ${range} in comment=${HEX}`));
  const open = [`### tuple ### limit tcp 22 0.0.0.0/0 any 0.0.0.0/0 in comment=${HEX}`, `### tuple ### limit tcp 22 ::/0 any ::/0 in comment=${HEX}`];
  return scoped && ![...rules, ...rules6].some((l) => open.includes(l));
}

async function scopeFirewall() {
  for (const range of PRIVATE) await $`sudo ufw limit from ${range} to any port 22 proto tcp comment omarchy-sshd`.quiet();
  // Omarchy's own rule; deleting it drops its IPv6 twin too.
  await $`sudo ufw delete limit 22/tcp`.quiet().nothrow();
  await $`sudo ufw reload`.quiet();
}

const serverReady = async () =>
  (await $`systemctl -q is-enabled sshd.service`.nothrow()).exitCode === 0 &&
  (await $`systemctl -q is-active sshd.service`.nothrow()).exitCode === 0 &&
  (await firewallScoped()) &&
  existsSync(HARDENING);

const same = (a: string[], b: string[]) => a.length === b.length && a.every((k, i) => k === b[i]);

async function check(...titles: string[]) {
  if (titles.length === 0) throw usage();
  const want = await githubKeys(titles);
  return (await serverReady()) && same(want, await authorized());
}

async function install(...titles: string[]) {
  if (titles.length === 0) throw usage();
  const want = await githubKeys(titles);
  const have = await authorized();
  let missing = want.filter((k) => !have.includes(k));
  // Nothing missing but the server isn't fully set up: one call with a key
  // it already trusts redoes the setup steps.
  if (missing.length === 0 && !(await serverReady())) missing = [want[0]];
  // One key per call; the setup script's sudo and pacman keep the terminal.
  for (const key of missing) {
    const code = await Bun.spawn(["omarchy-setup-security-sshd", `--key=${key}`], { stdio: ["inherit", "inherit", "inherit"] }).exited;
    if (code !== 0) throw new Error(`omarchy-setup-security-sshd failed (exit ${code})`);
  }
  if (!(await firewallScoped())) await scopeFirewall();
  // Drop keys GitHub no longer has. Only after the additions: the hardening
  // step refuses to turn passwords off with an empty authorized_keys. Written
  // in place, so the file keeps its mode.
  const kept = (await read(AUTHORIZED_KEYS)).split("\n").filter((l) => !KEY.test(l) || want.includes(ident(l)));
  writeFileSync(AUTHORIZED_KEYS, kept.join("\n"));
  if (!((await serverReady()) && same(want, await authorized()))) {
    throw new Error("sshd setup or authorized_keys doesn't match GitHub after install");
  }
}

await main(check, install);
