// Omarchy web apps: `omarchyWebappsRemove({ names: ["Basecamp", "HEY"] })`.
import { script } from "loadout";

// The web apps the machine names, removed the native way and kept removed
// across re-provisioning.
export const omarchyWebappsRemove = script("omarchy-webapps-remove", { description: "Omarchy web apps removed", module: () => import("./.loadout/omarchy-webapps-remove.ts"), rules: () => import("./.loadout/omarchy-webapps-remove.rules.ts") });

export const omarchyWebappGmail = script("omarchy-webapp-gmail", {
  description: "Gmail web app, the default for email links",
  module: () => import("./.loadout/omarchy-webapp-gmail.ts"),
  runAfter: [omarchyWebappsRemove],  // HEY's launcher claims mailto too
});

export const omarchyWebappGoogleCalendar = script("omarchy-webapp-google-calendar", { description: "Google Calendar web app", module: () => import("./.loadout/omarchy-webapp-google-calendar.ts") });

export const omarchyWebappClaude = script("omarchy-webapp-claude", {
  description: "Claude web app, the AI overlay's main app (Hyper+A)",
  module: () => import("./.loadout/omarchy-webapp-claude.ts"),
});
