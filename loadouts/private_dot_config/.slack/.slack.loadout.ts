// Slack: from the AUR.
import { omarchyAur, program, via } from "loadout";

export const slack = program("slack", {
  description: "Slack desktop app",
  later: "a large app download; nothing in setup needs it",
  install: [
    via(omarchyAur, { pkg: "slack-desktop" }),  // Slack's own build, repackaged
  ],
});
