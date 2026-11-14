import { args, omarchy, profile, via } from "loadout";
import type { Data } from "../data.ts";
import { kait2en, t2BcmFirmware, t2ChargeLimit, t2ForceClickDaemon, t2GmuxBacklight, t2HidAppleKeyboard, t2IbridgeUnmanaged, t2KernelArgs, t2OmarchyChannel, t2PostUpdateCheck, t2RenderGpu, t2SmcGaugingd } from "../../loadouts/.etc/t2/.t2.loadout.ts";
import { omarchySshd } from "../../loadouts/.ssh/.omarchy-sshd.loadout.ts";
import { sshKey } from "../../loadouts/.ssh/.ssh.loadout.ts";
import { omarchyActivityMonitorSize } from "../../loadouts/private_dot_config/.hypr/.hyprland.loadout.ts";
import { archVirtualization, setupLibvirt, ufwLibvirt } from "../../loadouts/private_dot_config/.libvirt/.libvirt.loadout.ts";
import { omarchySudolessDocker } from "../../loadouts/private_dot_config/.omarchy/.omarchy-apps.loadout.ts";
import { omarchyScratchpadOpacity } from "../../loadouts/private_dot_config/.omarchy/.omarchy-scratchpad.loadout.ts";
import { solaar, solaarNoAutostart } from "../../loadouts/private_dot_config/.solaar.loadout.ts";
import { rocmSmiLib } from "../../loadouts/private_dot_config/btop/.btop.loadout.ts";
import { omarchyProfile } from "./omarchy.profile.loadout.ts";

// Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
// these machines run on top of Omarchy. Each install is its own machine
// (named by its hostname, so each keeps its own state file).
export const t2Macbook = profile<Data>("t2-macbook", {
  extends: [omarchyProfile],
  install: [
    via(omarchy, [
      kait2en,  // KaiT2en's T2 drivers on linux-omarchy, and their repo
      archVirtualization,
      solaar,
      rocmSmiLib,  // btop's stats for the Radeon Pro 5300M/5500M
    ]),
  ],
  run: [
    sshKey("id_ed25519"),
    // The GitHub keys (by title) that get a shell here.
    args(omarchySshd, "t2-macbook-omarchy", "t2-macbook-omarchy-2", "omarchy-vm", "work-mac"),
    t2OmarchyChannel,
    t2HidAppleKeyboard,
    t2KernelArgs,
    t2GmuxBacklight,
    t2BcmFirmware,
    t2RenderGpu,
    t2IbridgeUnmanaged,
    args(t2ChargeLimit, "85"),
    t2SmcGaugingd,
    t2ForceClickDaemon,
    t2PostUpdateCheck,
    setupLibvirt,
    ufwLibvirt,
    omarchySudolessDocker,
    args(omarchyActivityMonitorSize, "90%", "90%"),
    args(omarchyScratchpadOpacity, "0.99"),
    solaarNoAutostart,
  ],
});
