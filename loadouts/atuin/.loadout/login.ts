// atuin logged in to its sync account, with this machine's history synced.
//
// check: `atuin status` doesn't say it's logged out. Offline, it fails with a
// connection error instead, which isn't logged out.
// install: runs `atuin login` on this terminal, which asks for the credentials,
// and waits as long as they take; a failed try (a wrong password) asks again, 3
// times in all. Without a terminal it waits for a login made in another one, as
// onepassword-signin does for the app's switch, up to ATUIN_LOGIN_WAIT seconds
// (default 900; 0 doesn't wait). Then the first sync, which needs the account's
// encryption key: if it fails the login is undone, or check would pass from
// then on and the wrong key never be noticed.
// No credential passes through here: atuin itself asks for them.
import { $ } from "loadout/script";
import { onTerminal, seconds, tell, waitForUser } from "#user";

const NAME = "atuin-login";
const WAIT = seconds("ATUIN_LOGIN_WAIT", 900);
const TRIES = 3;

export async function check() {
  if (!Bun.which("atuin")) return false;
  const status = await $`atuin status 2>&1`.quiet().nothrow();
  return !/not logged in/i.test(status.stdout.toString());
}

async function askHere() {
  tell(`
==> Log in to atuin. Have ready, from 1Password:
      1. your atuin username and password
      2. the encryption key ("atuin key" on a machine that's logged in): never
         leave it blank on a new machine, or its history can't be shared
    No account yet: "atuin register" in another terminal, then come back.`);
  for (let tries = 1; ; tries++) {
    try {
      await onTerminal("atuin", "login");
    } catch (error) {
      // Registered or logged in from another terminal meanwhile.
      if (await check()) return;
      if (tries === TRIES) throw error;
    }
    if (await check()) return;
    if (tries === TRIES) throw new Error(`${NAME}: still not logged in after ${TRIES} tries; run this again`);
    console.warn(`${NAME}: that didn't log in, try again (${tries + 1} of ${TRIES})`);
  }
}

export async function install() {
  if (!Bun.which("atuin")) throw new Error(`${NAME}: atuin isn't installed`);
  if (await check()) return;
  if (process.stdin.isTTY) {
    await askHere();
  } else {
    await waitForUser(NAME, check, {
      wait: WAIT,
      instructions: `Waiting for the atuin login (up to {wait}). In another terminal:
      atuin login      (or "atuin register" without an account)
    This goes on by itself once it's done.`,
    });
  }
  console.warn(`${NAME}: logged in; syncing the history…`);
  if ((await $`atuin sync`.nothrow()).exitCode !== 0) {
    await $`atuin logout`.quiet().nothrow();
    throw new Error(`${NAME}: the first sync failed (a wrong encryption key, or no network), so it's logged out again; run this again`);
  }
}
