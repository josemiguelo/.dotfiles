import { omarchyAur, program, via } from "loadout";

export const teamsForLinux = program("teams-for-linux", {
  description: "Microsoft Teams client",
  later: "a large app download; nothing in setup needs it",
  install: [
    via(omarchyAur, { pkg: "teams-for-linux-bin" }),  // the source package rebuilds Electron
  ],
});
