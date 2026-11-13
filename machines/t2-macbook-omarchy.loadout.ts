import { args, machine, omarchy, via } from "loadout";
import type { Data } from "./data.ts";
import { bareRepos, kait2enDev } from "../loadouts/.repos/.repos.loadout.ts";
import { intentionalSync } from "../loadouts/private_dot_config/.intentional/.intentional.loadout.ts";
import { omarchyIsoTestDeps } from "../loadouts/private_dot_config/.omarchy-iso-test.loadout.ts";
import { t2Macbook } from "./profiles/t2-macbook.profile.loadout.ts";

// MacBookPro16,1 (T2) running Omarchy.
machine<Data>("t2-macbook-omarchy", {
  extends: [t2Macbook],
  install: [
    // Omarchy ISO testing, also on fake hardware (omarchy-iso-test --fake-pci).
    via(omarchy, [omarchyIsoTestDeps]),
  ],
  run: [
    // The name this machine has synced under since Intentional's sync began.
    args(intentionalSync, "t2-macbook"),
    // The KaiT2en -> Omarchy work: its repos, then the rest (docs/t2-macbook.md).
    args(bareRepos, "t2-arch-packages", "omarchy", "omarchy-iso"),
    kait2enDev,
  ],
});
