// T2 Macs (MacBookPro16,1) on linux-omarchy with KaiT2en's T2 drivers: their
// packages and repo, the Wi-Fi firmware, the EC clock, the internal keyboard,
// the screen backlight and the GPU Hyprland renders on (docs/t2-macbook.md).
import { omarchy, program, script, via } from "loadout";
import { onepasswordCli } from "../../private_dot_config/.1password/.1password.loadout.ts";
import { omarchyCommandOverrides } from "../../private_dot_config/.omarchy/.omarchy-overrides.loadout.ts";

// The [t2-arch-packages] repo (github.com/josemiguelo/t2-arch-packages):
// KaiT2en's drivers and tools packaged for linux-omarchy, signed. Omarchy's
// installer adds it on T2 Macs (the t2-kait2en branch's fix-t2.sh), but
// `omarchy refresh pacman` rewrites pacman.conf without it; this keeps it, its
// key trusted, and a pre-refresh-pacman hook that puts it back.
export const t2ArchPackagesRepo = program("t2-arch-packages-repo", {
  description: "the signed [t2-arch-packages] pacman repo, kept across pacman.conf refreshes",
  install: [via(omarchy, { managedBy: ".loadout/arch-packages-repo.ts", needsSudo: true })],
});

// KaiT2en's drivers and tools, one program per package so each keeps its own
// version in state; kait2en below keeps the profile to one line. An ISO
// install already has them (fix-t2.sh); elsewhere they wait for the repo.
export const t2bceStackDkms = program("t2bce-stack-dkms", {
  description: "T2 BCE bus: internal keyboard/trackpad, audio transport (DKMS)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2smcDkms = program("t2smc-dkms", {
  description: "T2 SMC: fans, charge limit, sensors, RTC (DKMS, replaces applesmc)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2sbsDkms = program("t2sbs-dkms", {
  description: "battery charge relative to full (DKMS, replaces sbs)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2smpDkms = program("t2smp-dkms", {
  description: "secondary CPUs offline around suspend: ~1 s wake (DKMS)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2thunderboltDkms = program("t2thunderbolt-dkms", {
  description: "Thunderbolt PM ordering, NHI before its ports (DKMS)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2PrecisionTrackpadDkms = program("t2-precision-trackpad-dkms", {
  description: "internal trackpad multitouch and Force Touch (DKMS; stock kernels see a plain mouse)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// Replaces t2-bluetooth-dkms (pacman's replaces=), which it grew from.
export const t2WirelessDkms = program("t2-wireless-dkms", {
  description: "brcmfmac and btbcm/hci_uart with KaiT2en's Apple fixes: Wi-Fi resume, Bluetooth LE devices (DKMS)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// Arch's own (extra): the APFS driver linux-t2 built in and linux-omarchy lacks.
export const linuxApfsRwDkms = program("linux-apfs-rw-dkms", {
  description: "APFS driver the Wi-Fi firmware fetcher mounts the macOS volume with (DKMS)",
  install: [omarchy],
});

export const t2FanControl = program("t2-fan-control", {
  description: "fan daemon and GTK app on t2smc (replaces t2fanrd)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// Its t2-smc-gaugingd lifts the charge limit for a full charge when the gauge
// needs one (t2SmcGaugingd keeps it running).
export const t2SmcControl = program("t2-smc-control", {
  description: "SMC app and battery gauging daemon on t2smc (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// The virtual bass plugin t2-dsp's speaker graphs run (AUR-only in Arch).
export const bankstownLv2 = program("bankstown-lv2", {
  description: "Bankstown bass enhancer LV2 plugin, for t2-dsp",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// The speaker and microphone processing macOS applies (PipeWire filter
// chains, KaiT2en's DSP): a udev rule renames the card t2-16_1 and the
// speakers' default output becomes "Mac 16,1 native DSP Speakers". Takes
// effect at the next boot.
export const t2Dsp = program("t2-dsp", {
  description: "speaker and mic DSP as PipeWire filter chains (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, bankstownLv2],
  install: [omarchy],
});

// The trackpad's Taptic Engine: a haptic click on force click. Its udev rule
// moves the haptic interface from hid-apple to it at boot and after resume.
export const t2TrackpadActuatorDkms = program("t2-trackpad-actuator-dkms", {
  description: "trackpad Taptic Engine driver: a haptic click on force click (DKMS)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// Click pressure, the force click threshold and an action bound to a force
// click; its daemon (t2ForceClickDaemon) applies them at boot.
export const t2ForceClick = program("t2-force-click", {
  description: "Force Touch settings app and daemon (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2TrackpadActuatorDkms],
  install: [omarchy],
});

export const t2bceAudioUcm = program("t2bce-audio-ucm", {
  description: "ALSA UCM profiles for the T2 audio driver",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2DkmsGuard = program("t2-dkms-guard", {
  description: "aborts linux-omarchy upgrades that would break the T2 DKMS modules",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2ArchPackagesKeyring = program("t2-arch-packages-keyring", {
  description: "the [t2-arch-packages] signing key, for pacman-key --populate",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const kait2en = [
  t2ArchPackagesRepo,
  t2ArchPackagesKeyring,
  t2bceStackDkms,
  t2smcDkms,
  t2sbsDkms,
  t2smpDkms,
  t2thunderboltDkms,
  t2PrecisionTrackpadDkms,
  t2WirelessDkms,
  linuxApfsRwDkms,
  t2FanControl,
  t2SmcControl,
  t2bceAudioUcm,
  t2TrackpadActuatorDkms,
  t2ForceClick,
  bankstownLv2,
  t2Dsp,
  t2DkmsGuard,
];

// The T2 Mac fixes, the t2-* scripts: `run: [t2GmuxBacklight]`.

// The Wi-Fi/Bluetooth firmware, which only macOS ships: copied off the macOS
// volume by apple-bcm-firmware-fetcher, or, with no macOS volume, the old
// apple-bcm-firmware package restored from a copy or 1Password. Not tracked as
// a program: the fallback replaces the fetcher, which conflicts with it.
export const t2BcmFirmware = script("t2-bcm-firmware", {
  description: "Wi-Fi firmware from the macOS volume, or apple-bcm-firmware 14.0-1 as the fallback",
  managedBy: ".loadout/bcm-firmware.ts",
  needsSudo: true,
  runAfter: [linuxApfsRwDkms, onepasswordCli],
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

// The KaiT2en kernel arguments Omarchy's installer writes for T2 Macs, kept
// against upstream migrations that rewrite /etc/limine-entry-tool.d/t2-mac.conf
// (#6562 once swapped pcie_ports=compat for pm_async=off). Next boot.
export const t2KernelArgs = script("t2-kernel-args", {
  description: "pci=noaer pcie_ports=compat for fast resume (T2 Mac, linux-omarchy)",
  managedBy: ".loadout/kernel-args.ts",
  needsSudo: true,
});

// The internal keyboard: Fn/Ctrl and Alt/Super swaps and the fnmode that
// keeps Fn+arrows working beside the touchbar. The boot image is rebuilt
// through Limine (limine-mkinitcpio).
export const t2HidAppleKeyboard = script("t2-hid-apple-keyboard", {
  description: "internal keyboard fn/ctrl swap and fnmode",
  managedBy: ".loadout/hid-apple-keyboard.ts",
  needsSudo: true,
});

// A sleep hook sends the backlight level back on resume; a udev rule puts it
// under systemd-backlight for reboots.
export const t2GmuxBacklight = script("t2-gmux-backlight", {
  description: "screen brightness kept across suspend and reboots (T2 Mac)",
  managedBy: ".loadout/gmux-backlight.ts",
  needsSudo: true,
  runAfter: [omarchyCommandOverrides],
});

// The battery's charge limit, named by the machine:
// `args(t2ChargeLimit, "85")`. The SMC keeps it across reboots (and
// in macOS); t2-smc-gaugingd lifts it for calibration charges.
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
  runAfter: [t2SmcControl],
});

// t2-force-click's root daemon: applies the saved click settings at boot and
// runs the action bound to a force click.
export const t2ForceClickDaemon = script("t2-force-click-daemon", {
  description: "the Force Touch daemon running (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-force-click.service",
  check: "systemctl -q is-enabled t2-force-click.service && systemctl -q is-active t2-force-click.service",
  runAfter: [t2ForceClick],
});

// An Omarchy post-update hook that asks loadout about the T2 items after each
// `omarchy update` and notifies when the update undid one.
export const t2PostUpdateCheck = script("t2-post-update-check", {
  description: "a check of the T2 setup after every omarchy update (T2 Mac)",
  managedBy: ".loadout/post-update-check.ts",
});

// The T2's internal USB network link (05ac:8233), macOS's line to the T2
// chip: no DHCP server answers on it, so NetworkManager would retry it every
// 45 s. A udev rule (also written by the fork's fix-t2.sh) unmanages it.
export const t2IbridgeUnmanaged = script("t2-ibridge-unmanaged", {
  description: "NetworkManager leaves the T2's internal USB network link alone (T2 Mac)",
  managedBy: ".loadout/ibridge-unmanaged.ts",
  needsSudo: true,
});

// Hyprland renders on whichever card has the panel connected (a uwsm env
// block), not the iGPU.
export const t2RenderGpu = script("t2-render-gpu", {
  description: "Hyprland renders on the GPU driving the panel (T2 Mac)",
  managedBy: ".loadout/render-gpu.ts",
});
