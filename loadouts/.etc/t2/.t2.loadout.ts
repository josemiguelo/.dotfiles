// T2 Macs (MacBookPro16,1) on linux-omarchy with KaiT2en's T2 drivers: their
// packages and repo, the Wi-Fi firmware, the EC clock, the internal keyboard,
// the screen backlight and the GPU Hyprland renders on (docs/t2-macbook.md).
import { omarchy, program, script, via } from "loadout";
import { onepasswordCli } from "../../private_dot_config/.1password/.1password.loadout.ts";
import { omarchyCommandOverrides } from "../../private_dot_config/.omarchy/.omarchy-overrides.loadout.ts";
import { omarchyBarOwnWidgets } from "../../private_dot_config/.omarchy/.omarchy-shell.loadout.ts";

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

// The thunderbolt driver with KaiT2en's Apple RTD3: the idle Titan Ridge
// controllers power off (the CPU package then reaches PC6/PC7) and the PM
// ordering t2thunderbolt-dkms added, which it replaces (conflicts).
export const t2ThunderboltDkms = program("t2-thunderbolt-dkms", {
  description: "Thunderbolt with the idle controllers powered off, and PM ordering (DKMS)",
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

// The T2 Mac's kernel arguments (pci=noaer pcie_ports=compat for a ~1 s wake,
// forced PCIe ASPM for deeper package C-states, ...), kept: the package owns
// /etc/limine-entry-tool.d/t2-mac.conf, and a path unit and a boot service
// write it back and rebuild the boot image whenever something else rewrites it
// (an Omarchy migration once swapped pcie_ports=compat for pm_async=off). It
// replaced this repo's t2-kernel-args script.
export const t2KernelArgs = program("t2-kernel-args", {
  description: "the T2 Mac's kernel arguments, kept in Limine's entries and boot image",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const kait2en = [
  t2ArchPackagesRepo,
  t2KernelArgs,
  t2ArchPackagesKeyring,
  t2bceStackDkms,
  t2smcDkms,
  t2sbsDkms,
  t2smpDkms,
  t2ThunderboltDkms,
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

// Touch ID: the T2 matches the finger in its Secure Enclave, and KaiT2en's
// t2-touchid daemon hands fprintd the result through libfprint's virtual
// storage driver. The package carries the daemon, its fprintd drop-in, the udev
// rule that brings the T2 link up, and the file Omarchy's fingerprint detection
// reads. fprintd and libfprint-git aren't programs here: Omarchy's fingerprint
// setup installs them (t2TouchIdAuth runs it) and its removal drops them.
export const t2Touchid = program("t2-touchid", {
  description: "Touch ID bridge from the T2's Secure Enclave to fprintd (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2TouchId = [t2Touchid];

// The Touch Bar and internal keyboard drivers (t2hid, t2touchbar_kbd/_bl,
// t2bdrm), installed inert: the package keeps them from autoloading, so
// hid-apple and the in-kernel Touch Bar drivers stay in charge until the
// switch-over (/etc/modprobe.d/t2-touchbar.conf).
export const t2TouchbarDkms = program("t2-touchbar-dkms", {
  description: "Touch Bar and keyboard drivers: t2hid, t2touchbar, t2bdrm (DKMS, KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// The Touch Bar daemon: draws its own bar on the Touch Bar's screen (t2bdrm),
// with a root attach service and a private seat; its user service runs for
// members of the t2-touchbar group.
export const t2Touchbar = program("t2-touchbar", {
  description: "Touch Bar daemon: media and F-key layers, swipes, custom keys, Touch ID prompt (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2TouchbarDkms],
  install: [omarchy],
});

// The keyboard backlight fades out after 30 s without input and back on the
// next one (t2KbdBacklightDaemon runs it); before suspend it puts the level
// back, so the keyboard resumes lit.
export const t2KbdBacklight = program("t2-kbd-backlight", {
  description: "keyboard backlight idle fade (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2TouchBar = [t2TouchbarDkms, t2Touchbar, t2KbdBacklight];

// Sharing files with phones: t2-drop is AirDrop with Apple devices over AWDL
// (t2-wireless-dkms's peer-to-peer Wi-Fi), t2-airshare the app and receiver
// for it and for Quick Share with Android. The receiver runs while the app's
// "visible" switch is on, which also makes the Mac discoverable over
// Bluetooth: that's left to the user.
export const t2Drop = program("t2-drop", {
  description: "AirDrop with Apple devices over AWDL (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2WirelessDkms],
  install: [omarchy],
});

export const t2Airshare = program("t2-airshare", {
  description: "Quick Share with Android and AirDrop with Apple devices (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2Drop],
  install: [omarchy],
});

export const t2Sharing = [t2Drop, t2Airshare];

// The ambient light sensor at work: t2-truetone (KaiT2en's, ported from GNOME
// to Hyprland) moves the screen's white point with the room's light (a gamma
// table, under Omarchy's night light) and its brightness along macOS's curve,
// learning from the brightness keys. A user service; the bar's Ambient Light
// widget switches it and its two halves.
export const t2Truetone = program("t2-truetone", {
  description: "True Tone and automatic brightness from the ambient light sensor (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2AmbientLight = [t2Truetone];

// Hybrid graphics: the Intel iGPU drives the panel and the Radeon powers off
// (D3cold) until an app asks for it (DRI_PRIME=1), ~20 W idle instead of
// 32 W. KaiT2en's gmux driver in place of apple_gmux, amdgpu with its GMUX
// runtime PM, i915 with its Apple panel patches and ours (the panel power
// cycled after a wake, or it stays dark), and t2-boot-gpu, which keeps Apple's
// boot GPU variable on the iGPU across macOS boots. External displays on the
// Thunderbolt ports need the dGPU: `sudo t2-boot-gpu discrete`, reboot.
export const t2gmuxDkms = program("t2gmux-dkms", {
  description: "gmux driver with the T2 dGPU power sequencing, in place of apple_gmux (DKMS, KaiT2en)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2AmdgpuDkms = program("t2-amdgpu-dkms", {
  description: "amdgpu with the Apple GMUX runtime PM: the dGPU off in hybrid mode (DKMS, KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2gmuxDkms],
  install: [omarchy],
});

export const t2I915Dkms = program("t2-i915-dkms", {
  description: "i915 with the Apple panel fixes and the wake retrain (DKMS, KaiT2en + ours)",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

export const t2BootGpu = program("t2-boot-gpu", {
  description: "keeps the boot GPU (hybrid or discrete) across macOS boots",
  dependsOn: [t2ArchPackagesRepo],
  install: [omarchy],
});

// Processor idle and power statistics (package C-states, watts), for
// checking what keeps the Mac from idling lower.
export const turbostat = program("turbostat", {
  description: "processor frequency, idle states and package power",
  install: [omarchy],
});

export const t2HybridGraphics = [t2gmuxDkms, t2AmdgpuDkms, t2I915Dkms, t2BootGpu, turbostat];

// KaiT2en's t2-services, over the T2 link t2-touchid's udev rule brings up:
// t2-journal merges the T2's own logs with the Linux journal (`t2journal -b`),
// t2-ave runs t2remote so the T2's HEVC and Sidecar encoders show up as V4L2
// devices (ffmpeg's hevc_v4l2m2m/h264_v4l2m2m; /usr/bin/ffmpeg, not Homebrew's).
export const t2Journal = program("t2-journal", {
  description: "the T2's bridgeOS logs merged with the Linux journal (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2Touchid],
  install: [omarchy],
});

export const t2Ave = program("t2-ave", {
  description: "the T2's HEVC and H.264 video encoders as V4L2 devices (KaiT2en)",
  dependsOn: [t2ArchPackagesRepo, t2Touchid],
  install: [omarchy],
});

export const t2Services = [t2Journal, t2Ave];

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

// The internal keyboard and Touch Bar on KaiT2en's drivers: t2hid (with the
// Fn/Ctrl and Alt/Super swaps) in the initramfs in place of hid-apple, the
// in-kernel Touch Bar drivers blacklisted, the user in the t2-touchbar group
// and the daemon enabled. Applies at the next boot (limine-mkinitcpio).
export const t2KbdBacklightDaemon = script("t2-kbd-backlight-daemon", {
  description: "the keyboard backlight idle fade running (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-kbd-backlight.service",
  check: "systemctl -q is-enabled t2-kbd-backlight.service && systemctl -q is-active t2-kbd-backlight.service",
  runAfter: [t2KbdBacklight],
});

// Hybrid mode from the next boot on, and kept there across macOS boots.
export const t2HybridBoot = script("t2-hybrid-boot", {
  description: "boots on the iGPU, the dGPU off until needed (T2 Mac, hybrid graphics; next boot)",
  needsSudo: true,
  run: "sudo t2-boot-gpu integrated && sudo systemctl enable t2-boot-gpu.service",
  check: "[ \"$(t2-boot-gpu)\" = integrated ] && grep -qx BOOT_GPU=integrated /etc/t2-boot-gpu.conf && systemctl -q is-enabled t2-boot-gpu.service",
  runAfter: [t2BootGpu, t2gmuxDkms, t2AmdgpuDkms, t2I915Dkms],
});

// The encoder daemon running, and its sessions closed around sleep.
export const t2AveDaemon = script("t2-ave-daemon", {
  description: "the T2 video encoders available (T2 Mac)",
  needsSudo: true,
  run: "sudo systemctl enable --now t2-ave.service t2-ave-suspend.service",
  check: "systemctl -q is-enabled t2-ave.service && systemctl -q is-enabled t2-ave-suspend.service && systemctl -q is-active t2-ave.service",
  runAfter: [t2Ave],
});

export const t2TruetoneDaemon = script("t2-truetone-daemon", {
  description: "True Tone and automatic brightness running (T2 Mac)",
  run: "systemctl --user enable --now t2-truetone.service",
  check: "systemctl --user -q is-enabled t2-truetone.service && systemctl --user -q is-active t2-truetone.service",
  runAfter: [t2Truetone],
});

// Omarchy's keyboard-backlight keys write the LED behind UPower's back, so the
// idle fade and the Touch Bar's glyphs missed them: a wrapper around
// omarchy-brightness-keyboard tells UPower the new level.
export const t2KbdBacklightSync = script("t2-kbd-backlight-sync", {
  description: "keyboard backlight keys reach UPower, for the idle fade and the Touch Bar (T2 Mac)",
  managedBy: ".loadout/kbd-backlight-sync.ts",
  runAfter: [omarchyCommandOverrides, t2KbdBacklight],
});

// AirShare in the Omarchy menu's Share submenu, beside LocalSend's entries.
export const t2AirshareMenu = script("t2-airshare-menu", {
  description: "AirShare entries in the Omarchy menu's Share submenu (T2 Mac)",
  managedBy: ".loadout/airshare-menu.ts",
  runAfter: [t2Airshare, omarchyBarOwnWidgets],
});

export const t2TouchbarSwitch = script("t2-touchbar-switch", {
  description: "internal keyboard and Touch Bar on t2hid, t2touchbar and t2-touchbar (T2 Mac; next boot)",
  managedBy: ".loadout/touchbar.ts",
  needsSudo: true,
  runAfter: [t2Touchbar],
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
// Touch ID for sudo, polkit and the lock screen, through Omarchy's own
// fingerprint setup (two touches): the daemon running, then that setup binds
// the finger enrolled in macOS and adds the PAM lines. Asks to log into macOS
// once when the Secure Enclave reports no fingers.
export const t2TouchIdAuth = script("t2-touch-id-auth", {
  description: "Touch ID for sudo, polkit and the lock screen (T2 Mac)",
  managedBy: ".loadout/touch-id.ts",
  needsSudo: true,
  runAfter: [t2Touchid],
});

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
