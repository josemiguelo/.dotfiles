// AnyDesk: from the AUR.
import { omarchyAur, program, via } from "loadout";

export const anydesk = program("anydesk", {
  description: "AnyDesk remote desktop",
  later: "a large app download; nothing in setup needs it",
  install: [
    // AnyDesk's own build; its unattended-access service is left disabled.
    via(omarchyAur, { pkg: "anydesk-bin" }),
  ],
});
