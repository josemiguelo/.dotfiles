import { machine } from "loadout";
import type { Data } from "./data.ts";
import { sshKey } from "../loadouts/.ssh/.ssh.loadout.ts";
import { omarchyProfile } from "./profiles/omarchy.profile.loadout.ts";

// A libvirt VM for testing a new-machine setup end to end: plain Omarchy, no
// T2 hardware, plus the ssh key.
machine<Data>("omarchy-vm", {
  extends: [omarchyProfile],
  run: sshKey("id_ed25519"),
});
