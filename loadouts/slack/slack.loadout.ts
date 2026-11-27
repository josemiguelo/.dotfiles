// Slack: from the AUR.
import { program, withOmarchyAur } from "loadout";

export const slack = program("slack", {
  description: "Slack desktop app",
  canWait: "a large app download; nothing in setup needs it",
  canBeInstalled: [
    withOmarchyAur({ packageName: "slack-desktop" }),  // Slack's own build, repackaged
  ],
});
