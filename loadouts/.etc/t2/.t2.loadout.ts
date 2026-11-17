// T2 Macs (MacBookPro16,1) on linux-omarchy with KaiT2en's T2 drivers: the
// setup only (the packages come with t2-mac and t2-mac-hybrid): the repo, the
// Wi-Fi firmware fallback, the stable channel, the internal keyboard's
// switch-over, the services enabled, the charge limit, Touch ID's PAM
// (docs/t2-macbook.md).
import { omarchy, program, script, via } from "loadout";
import { onepasswordCli } from "../../private_dot_config/.1password/.1password.loadout.ts";

// The [t2-arch-packages] repo (github.com/josemiguelo/t2-arch-packages):
// KaiT2en's drivers and tools packaged for linux-omarchy, signed. Omarchy's
// installer adds it on T2 Macs (the t2-kait2en branch's fix-t2.sh), but
// `omarchy refresh pacman` rewrites pacman.conf without it; this keeps it, its
// key trusted, and a pre-refresh-pacman hook that puts it back.
export const t2ArchPackagesRepo = program("t2-arch-packages-repo", {
  description: "the signed [t2-arch-packages] pacman repo, kept across pacman.conf refreshes",
  install: [via(omarchy, { managedBy: ".loadout/arch-packages-repo.ts", needsSudo: true })],
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
  managedBy: ".loadout/bcm-firmware.ts",
  needsSudo: true,
  runAfter: [onepasswordCli],
});

// Omarchy's stable channel, which the T2 ISO is built for (--stable): an ISO
// built without it installs edge and says nothing. Runs after the repo's
// pre-refresh-pacman hook is in place, since a channel switch rewrites
// pacman.conf.
export const t2OmarchyChannel = script("t2-omarchy-channel", {
  description: "Omarchy on the stable channel, as the T2 ISO is built (T2 Mac)",
  managedBy: ".loadout/omarchy-channel.ts",
  needsSudo: true,
  runAfter: [t2ArchPackagesRepo],
});

// The keyboard backlight's idle fade (t2-kbd-backlight) enabled.
export const t2KbdBacklightDaemon = script("t2-kbd-backlight-daemon", {
  description: "the keyboard backlight idle fade running (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-kbd-backlight.service",
  check: "systemctl -q is-enabled t2-kbd-backlight.service && systemctl -q is-active t2-kbd-backlight.service",
});

// Hybrid mode from the next boot on, and kept there across macOS boots.
export const t2HybridBoot = script("t2-hybrid-boot", {
  description: "boots on the iGPU, the dGPU off until needed (T2 Mac, hybrid graphics; next boot)",
  needsSudo: true,
  run: "sudo t2-boot-gpu integrated && sudo systemctl enable t2-boot-gpu.service",
  check: "[ \"$(t2-boot-gpu)\" = integrated ] && grep -qx BOOT_GPU=integrated /etc/t2-boot-gpu.conf && systemctl -q is-enabled t2-boot-gpu.service",
});

// The encoder daemon running, and its sessions closed around sleep.
export const t2AveDaemon = script("t2-ave-daemon", {
  description: "the T2 video encoders available (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-ave.service t2-ave-suspend.service",
  check: "systemctl -q is-enabled t2-ave.service && systemctl -q is-enabled t2-ave-suspend.service && systemctl -q is-active t2-ave.service",
});

export const t2TruetoneDaemon = script("t2-truetone-daemon", {
  description: "True Tone and automatic brightness running (T2 Mac)",
  run: "systemctl --user enable --now t2-truetone.service",
  check: "systemctl --user -q is-enabled t2-truetone.service && systemctl --user -q is-active t2-truetone.service",
});

// The internal keyboard and Touch Bar on KaiT2en's drivers: t2hid (with the
// Fn/Ctrl and Alt/Super swaps) in the initramfs in place of hid-apple, the
// in-kernel Touch Bar drivers blacklisted, the user in the t2-touchbar group
// and the daemon enabled. Applies at the next boot (limine-mkinitcpio).
export const t2TouchbarSwitch = script("t2-touchbar-switch", {
  description: "internal keyboard and Touch Bar on t2hid, t2touchbar and t2-touchbar (T2 Mac; next boot)",
  managedBy: ".loadout/touchbar.ts",
  needsSudo: true,
});

// The battery's charge limit, named by the machine:
// `args(t2ChargeLimit, "90")`: the SMC stops charging 5 points below the
// limit (90 holds 85 %), so the argument is the limit, not the level reached.
// The SMC keeps it across reboots, but macOS
// may change it, so a boot unit (t2-charge-limit.service) writes it again;
// t2-smc-gaugingd lifts it for calibration charges.
export const t2ChargeLimit = script("t2-charge-limit", {
  description: "battery charge limit in the T2 SMC (T2 Mac)",
  managedBy: ".loadout/charge-limit.ts",
  needsSudo: true,
});

// A permanent charge limit keeps the battery gauge from recalibrating:
// t2-smc-gaugingd lifts it for a full charge when the gauge's DOD0 is 3 days
// old or the last full charge 21, as powerd does on macOS.
export const t2SmcGaugingd = script("t2-smc-gaugingd", {
  description: "battery gauge calibration charges under the charge limit (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-smc-gaugingd.service",
  check: "systemctl -q is-enabled t2-smc-gaugingd.service && systemctl -q is-active t2-smc-gaugingd.service",
});

// t2-force-click's root daemon: applies the saved click settings at boot and
// runs the action bound to a force click.
export const t2ForceClickDaemon = script("t2-force-click-daemon", {
  description: "the Force Touch daemon running (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-force-click.service",
  check: "systemctl -q is-enabled t2-force-click.service && systemctl -q is-active t2-force-click.service",
});

// An Omarchy post-update hook that asks loadout about the T2 items after each
// `omarchy update` and notifies when the update undid one.
export const t2PostUpdateCheck = script("t2-post-update-check", {
  description: "a check of the T2 setup after every omarchy update (T2 Mac)",
  managedBy: ".loadout/post-update-check.ts",
});

// Touch ID for sudo, polkit and the lock screen, through Omarchy's own
// fingerprint setup (two touches): the daemon running, then that setup binds
// the finger enrolled in macOS and adds the PAM lines. Asks to log into macOS
// once when the Secure Enclave reports no fingers.
export const t2TouchIdAuth = script("t2-touch-id-auth", {
  description: "Touch ID for sudo, polkit and the lock screen (T2 Mac)",
  managedBy: ".loadout/touch-id.ts",
  needsSudo: true,
});

