// T2 Macs (MacBookPro16,1) on linux-omarchy with KaiT2en's T2 drivers: the
// owner's preferences and per-person setup only. The packages come with t2-mac
// and t2-mac-hybrid; the services a feature needs, the keyboard switch-over and
// the firewall rules are the Omarchy fork's install (fix-t2.sh); per-user
// pieces (the T2 panel, menu entries, the hook that keeps the repo across
// `omarchy refresh pacman`) are t2-omarchy-setup's. Here: the repo and its key,
// the Wi-Fi firmware fallback, the stable channel, the key swaps, Hybrid once,
// the charge limit, Touch ID's finger and PAM (docs/t2-macbook.md).
import { program, script, withOmarchy } from "loadout";
import { onepasswordSignin } from "../1password/1password.loadout.ts";

// The [t2-arch-packages] repo (github.com/josemiguelo/t2-arch-packages):
// KaiT2en's drivers and tools packaged for linux-omarchy, signed. Omarchy's
// installer adds it on T2 Macs (the t2-kait2en branch's fix-t2.sh), and
// t2-omarchy-plugins' hook puts it back after `omarchy refresh pacman`; this
// only makes sure it's there and its key trusted.
export const t2ArchPackagesRepo = program("t2-arch-packages-repo", {
  description: "the signed [t2-arch-packages] pacman repo, kept across pacman.conf refreshes",
  canBeInstalled: [withOmarchy({ module: () => import("./.loadout/arch-packages-repo.ts"), needsSudo: true })],
});

// The T2 packages themselves (drivers, services, apps) aren't listed here: the
// t2-mac meta-package (t2-mac-hybrid on dual-GPU models) carries them, which the
// Omarchy fork's installer installs and `pacman -Syu` keeps complete. What
// follows only configures and sets them up.

// The T2 Mac fixes, the t2-* scripts: `run: [t2ChargeLimit]`.

// The Wi-Fi/Bluetooth firmware, which only macOS ships: copied off the macOS
// volume by apple-bcm-firmware-fetcher, or, with no macOS volume, the old
// apple-bcm-firmware package restored from a copy or 1Password. Not tracked as
// a program: the fallback replaces the fetcher, which conflicts with it.
export const t2BcmFirmware = script("t2-bcm-firmware", {
  description: "Wi-Fi firmware from the macOS volume, or apple-bcm-firmware 14.0-1 as the fallback",
  module: () => import("./.loadout/bcm-firmware.ts"),
  needsSudo: true,
  runAfter: [onepasswordSignin],
});

// Omarchy's stable channel, which the T2 ISO is built for (--stable): an ISO
// built without it installs edge and says nothing. Runs after the repo's
// pre-refresh-pacman hook is in place, since a channel switch rewrites
// pacman.conf.
export const t2OmarchyChannel = script("t2-omarchy-channel", {
  description: "Omarchy on the stable channel, as the T2 ISO is built (T2 Mac)",
  module: () => import("./.loadout/omarchy-channel.ts"),
  needsSudo: true,
  runAfter: [t2ArchPackagesRepo],
});

// Hybrid as the boot GPU on a machine where nothing is chosen yet (the fork's
// t2-boot-gpu.service keeps the choice across macOS boots). After that the
// choice is the T2 panel's Graphics tab (Hybrid or Discrete, which external
// displays need): whichever is kept isn't drift.
export const t2HybridBoot = script("t2-hybrid-boot", {
  description: "Hybrid graphics unless a boot GPU is chosen in the T2 panel (T2 Mac, dual GPU; next boot)",
  needsSudo: true,
  runCommand: "grep -qE '^BOOT_GPU=(integrated|discrete)$' /etc/t2-boot-gpu.conf 2>/dev/null || sudo t2-boot-gpu integrated",
  checkCommand: "grep -qE '^BOOT_GPU=(integrated|discrete)$' /etc/t2-boot-gpu.conf",
});

// The owner's layout on the internal keyboard (t2hid, which the fork's install
// puts in place): Ctrl in the bottom-left corner, Fn where "control" is,
// Alt/Super swapped. At once, and in the initramfs for the unlock prompt.
export const t2KeySwaps = script("t2-key-swaps", {
  description: "Ctrl/Fn and Alt/Super swapped on the internal keyboard (T2 Mac)",
  module: () => import("./.loadout/key-swaps.ts"),
  needsSudo: true,
});

// The battery's charge limit, named by the machine:
// `t2ChargeLimit({ limit: 90 })`: the SMC stops charging 5 points below the
// limit (90 holds 85 %), so it names the limit, not the level reached.
// The SMC keeps it across reboots, but macOS
// may change it, so the fork's boot unit (t2-charge-limit.service) writes it again;
// t2-smc-gaugingd lifts it for calibration charges.
export const t2ChargeLimit = script("t2-charge-limit", {
  description: "battery charge limit in the T2 SMC (T2 Mac)",
  module: () => import("./.loadout/charge-limit.ts"),
  rules: () => import("./.loadout/charge-limit.rules.ts"),
  needsSudo: true,
});

// An Omarchy post-update hook that asks loadout about the T2 items after each
// `omarchy update` and notifies when the update undid one.
export const t2PostUpdateCheck = script("t2-post-update-check", {
  description: "a check of the T2 setup after every omarchy update (T2 Mac)",
  module: () => import("./.loadout/post-update-check.ts"),
});

// Touch ID for sudo, polkit and the lock screen, through Omarchy's own
// fingerprint setup (two touches): the daemon (the fork enables it) told to
// bind no user itself, then that setup binds
// the finger enrolled in macOS and adds the PAM lines. Asks to log into macOS
// once when the Secure Enclave reports no fingers.
export const t2TouchIdAuth = script("t2-touch-id-auth", {
  description: "Touch ID for sudo, polkit and the lock screen (T2 Mac)",
  module: () => import("./.loadout/touch-id.ts"),
  needsSudo: true,
});

