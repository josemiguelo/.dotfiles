// Google Calendar as an Omarchy web app (its own app window), with Omarchy's
// own omarchy-webapp-install.
import { webapp } from "#webapp";

export const { check, install } = webapp({
  name: "Google Calendar",
  url: "https://calendar.google.com/",
  icon: "https://cdn.jsdelivr.net/gh/homarr-labs/dashboard-icons/png/google-calendar.png",
  host: /calendar\.google\.com/,
});
