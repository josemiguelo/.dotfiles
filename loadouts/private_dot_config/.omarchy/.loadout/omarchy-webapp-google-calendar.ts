#!/usr/bin/env bun
// Google Calendar as an Omarchy web app (its own app window), with Omarchy's
// own omarchy-webapp-install.
// Modes: `check` / `install` (default).
import { webapp } from "#webapp";

await webapp({
  name: "Google Calendar",
  url: "https://calendar.google.com/",
  icon: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-calendar.png",
  host: /calendar\.google\.com/,
});
