#!/usr/bin/env bun
// Claude (claude.ai) as an Omarchy web app (its own app window), with
// Omarchy's own omarchy-webapp-install. It's the main app of the AI overlay
// on Hyper+A (.hypr/.loadout/omarchy-harpoon/bindings.lua).
// Modes: `check` / `install` (default).
import { webapp } from "#webapp";

await webapp({
  name: "Claude",
  url: "https://claude.ai/",
  icon: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/claude-ai.png",
  host: /claude\.ai/,
});
