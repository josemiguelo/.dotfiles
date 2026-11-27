import { program, withOmarchyAur } from "loadout";

export const teamsForLinux = program("teams-for-linux", {
  description: "Microsoft Teams client",
  canWait: "a large app download; nothing in setup needs it",
  canBeInstalled: [
    withOmarchyAur({ packageName: "teams-for-linux-bin" }),  // the source package rebuilds Electron
  ],
});
