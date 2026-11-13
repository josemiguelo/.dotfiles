#!/usr/bin/env bun
// Gmail as an Omarchy web app (its own app window, like HEY) and as the
// mailto handler — the way Omarchy wires HEY: a handler command in the
// launcher's Exec (omarchy-webapp-handler-hey there), the launcher declaring
// x-scheme-handler/mailto, and xdg-mime making it the default. The handler
// is named like Omarchy's so Omarchy's own web-app tools list and remove it.
// Modes: `check` / `install` (default).
import { $, main, out, read } from "loadout/script";
import { executableHolds, writeExecutable } from "#omarchy";

const HOME = process.env.HOME!;
const HANDLER = `${HOME}/.local/bin/omarchy-webapp-handler-gmail`;
const DESKTOP = `${HOME}/.local/share/applications/Gmail.desktop`;
const ICON = "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/gmail.png";

const handler = `#!/bin/sh
# Managed by loadout (omarchy-webapp-gmail): open Gmail, turning a mailto:
# link into Gmail's compose — what omarchy-webapp-handler-hey does for HEY.
url=\${1:-}
web=https://mail.google.com/
case $url in
mailto:*) web="https://mail.google.com/mail/?extsrc=mailto&url=$(jq -rn --arg u "$url" '$u | @uri')" ;;
esac
exec omarchy-launch-webapp "$web"
`;

async function ready() {
  const desktop = await read(DESKTOP);
  return (
    (await executableHolds(HANDLER, handler)) &&
    desktop.split("\n").includes("Exec=omarchy-webapp-handler-gmail %u") &&
    /^MimeType=.*x-scheme-handler\/mailto/m.test(desktop) &&
    (await out($`xdg-mime query default x-scheme-handler/mailto`)) === "Gmail.desktop"
  );
}

async function install() {
  await writeExecutable(HANDLER, handler);
  await $`omarchy-webapp-install Gmail https://mail.google.com/ ${ICON} ${"omarchy-webapp-handler-gmail %u"} ${"x-scheme-handler/mailto;"}`;
  await $`xdg-mime default Gmail.desktop x-scheme-handler/mailto`;
  if (!(await ready())) throw new Error("Gmail web app or mailto default not in place after install");
}

await main(ready, install);
