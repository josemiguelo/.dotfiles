// AnyDesk: from the AUR.
import { program, withOmarchyAur } from "loadout";

export const anydesk = program("anydesk", {
  description: "AnyDesk remote desktop",
  canWait: "a large app download; nothing in setup needs it",
  canBeInstalled: [
    // AnyDesk's own build; its unattended-access service is left disabled.
    withOmarchyAur({ packageName: "anydesk-bin" }),
  ],
});
