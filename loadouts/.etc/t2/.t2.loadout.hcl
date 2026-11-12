# T2 Macs (MacBookPro16,1) on linux-omarchy with KaiT2en's T2 drivers: their
# packages and repo, the Wi-Fi firmware, the EC clock, the internal keyboard,
# the screen backlight and the GPU Hyprland renders on (docs/t2-macbook.md).

# The [t2-arch-packages] repo (github.com/josemiguelo/t2-arch-packages):
# KaiT2en's drivers and tools packaged for linux-omarchy, signed. Omarchy's
# installer adds it on T2 Macs (the t2-kait2en branch's fix-t2.sh), but
# `omarchy refresh pacman` rewrites pacman.conf without it; this keeps it, its
# key trusted, and a pre-refresh-pacman hook that puts it back.
program "t2-arch-packages-repo" {
  description = "the signed [t2-arch-packages] pacman repo, kept across pacman.conf refreshes"

  via "omarchy" {
    managed_by = ".loadout/arch-packages-repo.sh"
    needs_sudo = true
  }
}

# KaiT2en's drivers and tools, one program per package so each keeps its own
# version in state; kait2en below keeps the profile to one line. An ISO
# install already has them (fix-t2.sh); elsewhere they wait for the repo.
program "t2bce-stack-dkms" {
  description = "T2 BCE bus: internal keyboard/trackpad, audio transport (DKMS)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2smc-dkms" {
  description = "T2 SMC: fans, charge limit, sensors, RTC (DKMS, replaces applesmc)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2sbs-dkms" {
  description = "battery charge relative to full (DKMS, replaces sbs)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2smp-dkms" {
  description = "secondary CPUs offline around suspend: ~1 s wake (DKMS)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2thunderbolt-dkms" {
  description = "Thunderbolt PM ordering, NHI before its ports (DKMS)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2-precision-trackpad-dkms" {
  description = "internal trackpad multitouch and Force Touch (DKMS; stock kernels see a plain mouse)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# Replaces t2-bluetooth-dkms (pacman's replaces=), which it grew from.
program "t2-wireless-dkms" {
  description = "brcmfmac and btbcm/hci_uart with KaiT2en's Apple fixes: Wi-Fi resume, Bluetooth LE devices (DKMS)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# Arch's own (extra): the APFS driver linux-t2 built in and linux-omarchy lacks.
program "linux-apfs-rw-dkms" {
  description = "APFS driver the Wi-Fi firmware fetcher mounts the macOS volume with (DKMS)"
  install_via = [omarchy]
}

program "t2-fan-control" {
  description = "fan daemon and GTK app on t2smc (replaces t2fanrd)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# Its t2-smc-gaugingd lifts the charge limit for a full charge when the gauge
# needs one (script.t2-smc-gaugingd keeps it running).
program "t2-smc-control" {
  description = "SMC app and battery gauging daemon on t2smc (KaiT2en)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# The speaker and microphone processing macOS applies (PipeWire filter
# chains, KaiT2en's DSP): a udev rule renames the card t2-16_1 and the
# speakers' default output becomes "Mac 16,1 native DSP Speakers". Takes
# effect at the next boot.
program "t2-dsp" {
  description = "speaker and mic DSP as PipeWire filter chains (KaiT2en)"
  depends_on  = [program.t2-arch-packages-repo, program.bankstown-lv2]
  install_via = [omarchy]
}

# The virtual bass plugin t2-dsp's speaker graphs run (AUR-only in Arch).
program "bankstown-lv2" {
  description = "Bankstown bass enhancer LV2 plugin, for t2-dsp"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# The trackpad's Taptic Engine: a haptic click on force click. Its udev rule
# moves the haptic interface from hid-apple to it at boot and after resume.
program "t2-trackpad-actuator-dkms" {
  description = "trackpad Taptic Engine driver: a haptic click on force click (DKMS)"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

# Click pressure, the force click threshold and an action bound to a force
# click; its daemon (script.t2-force-click-daemon) applies them at boot.
program "t2-force-click" {
  description = "Force Touch settings app and daemon (KaiT2en)"
  depends_on  = [program.t2-arch-packages-repo, program.t2-trackpad-actuator-dkms]
  install_via = [omarchy]
}

program "t2bce-audio-ucm" {
  description = "ALSA UCM profiles for the T2 audio driver"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2-dkms-guard" {
  description = "aborts linux-omarchy upgrades that would break the T2 DKMS modules"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

program "t2-arch-packages-keyring" {
  description = "the [t2-arch-packages] signing key, for pacman-key --populate"
  depends_on  = [program.t2-arch-packages-repo]
  install_via = [omarchy]
}

locals {
  kait2en = [
    program.t2-arch-packages-repo,
    program.t2-arch-packages-keyring,
    program.t2bce-stack-dkms,
    program.t2smc-dkms,
    program.t2sbs-dkms,
    program.t2smp-dkms,
    program.t2thunderbolt-dkms,
    program.t2-precision-trackpad-dkms,
    program.t2-wireless-dkms,
    program.linux-apfs-rw-dkms,
    program.t2-fan-control,
    program.t2-smc-control,
    program.t2bce-audio-ucm,
    program.t2-trackpad-actuator-dkms,
    program.t2-force-click,
    program.bankstown-lv2,
    program.t2-dsp,
    program.t2-dkms-guard,
  ]
}

# The T2 Mac fixes, the t2-* scripts: `run = [script.t2-boot-clock]`.

# The Wi-Fi/Bluetooth firmware, which only macOS ships: copied off the macOS
# volume by apple-bcm-firmware-fetcher, or, with no macOS volume, the old
# apple-bcm-firmware package restored from a copy or 1Password. Not tracked as
# a program: the fallback replaces the fetcher, which conflicts with it.
script "t2-bcm-firmware" {
  description = "Wi-Fi firmware from the macOS volume, or apple-bcm-firmware 14.0-1 as the fallback"
  managed_by  = ".loadout/bcm-firmware.ts"
  needs_sudo  = true
  run_after   = [program.linux-apfs-rw-dkms, script.onepassword-cli]
}

# Omarchy's stable channel, which the T2 ISO is built for (--stable): an ISO
# built without it installs edge and says nothing. Runs after the repo's
# pre-refresh-pacman hook is in place, since a channel switch rewrites
# pacman.conf.
script "t2-omarchy-channel" {
  description = "Omarchy on the stable channel, as the T2 ISO is built (T2 Mac)"
  managed_by  = ".loadout/omarchy-channel.ts"
  needs_sudo  = true
  run_after   = [program.t2-arch-packages-repo]
}

# The KaiT2en kernel arguments Omarchy's installer writes for T2 Macs, kept
# against upstream migrations that rewrite /etc/limine-entry-tool.d/t2-mac.conf
# (#6562 once swapped pcie_ports=compat for pm_async=off). Next boot.
script "t2-kernel-args" {
  description = "pci=noaer pcie_ports=compat for fast resume (T2 Mac, linux-omarchy)"
  managed_by  = ".loadout/kernel-args.ts"
  needs_sudo  = true
}

# The real clock lives in the EC: t2smc reaches it (read and write), the
# legacy CMOS rtc only reads it. Writes it back at shutdown.
script "t2-boot-clock" {
  description = "keep the EC hardware clock set (T2 Mac)"
  managed_by  = ".loadout/boot-clock.ts"
  needs_sudo  = true
}

# The internal keyboard: Fn/Ctrl and Alt/Super swaps and the fnmode that
# keeps Fn+arrows working beside the touchbar. Two ways to rebuild the
# boot image; the machine picks.
script "t2-hid-apple-keyboard" {
  description = "internal keyboard fn/ctrl swap and fnmode"
  needs_sudo  = true

  variant "arch" {  # Limine (limine-mkinitcpio)
    managed_by = ".loadout/hid-apple-keyboard-arch.ts"
  }

  # dracut
  variant "fedora" {
    spare      = "no machine runs Fedora today"
    managed_by = ".loadout/hid-apple-keyboard.ts"
  }
}

# A sleep hook sends the backlight level back on resume; a udev rule puts it
# under systemd-backlight for reboots.
script "t2-gmux-backlight" {
  description = "screen brightness kept across suspend and reboots (T2 Mac)"
  managed_by  = ".loadout/gmux-backlight.ts"
  needs_sudo  = true
  run_after   = [script.omarchy-command-overrides]
}

# The battery's charge limit, named by the machine:
# `args(script.t2-charge-limit, "85")`. The SMC keeps it across reboots (and
# in macOS); t2-smc-gaugingd lifts it for calibration charges.
script "t2-charge-limit" {
  description = "battery charge limit in the T2 SMC (T2 Mac)"
  managed_by  = ".loadout/charge-limit.ts"
  needs_sudo  = true
}

# A permanent charge limit keeps the battery gauge from recalibrating:
# t2-smc-gaugingd lifts it for a full charge when the gauge's DOD0 is 3 days
# old or the last full charge 21, as powerd does on macOS.
script "t2-smc-gaugingd" {
  description = "battery gauge calibration charges under the charge limit (T2 Mac)"
  needs_sudo  = true
  run         = "sudo systemctl enable --now t2-smc-gaugingd.service"
  check       = "systemctl -q is-enabled t2-smc-gaugingd.service && systemctl -q is-active t2-smc-gaugingd.service"
  run_after   = [program.t2-smc-control]
}

# t2-force-click's root daemon: applies the saved click settings at boot and
# runs the action bound to a force click.
script "t2-force-click-daemon" {
  description = "the Force Touch daemon running (T2 Mac)"
  needs_sudo  = true
  run         = "sudo systemctl enable --now t2-force-click.service"
  check       = "systemctl -q is-enabled t2-force-click.service && systemctl -q is-active t2-force-click.service"
  run_after   = [program.t2-force-click]
}

# The T2's internal USB network link (05ac:8233), macOS's line to the T2
# chip: no DHCP server answers on it, so NetworkManager would retry it every
# 45 s. A udev rule (also written by the fork's fix-t2.sh) unmanages it.
script "t2-ibridge-unmanaged" {
  description = "NetworkManager leaves the T2's internal USB network link alone (T2 Mac)"
  managed_by  = ".loadout/ibridge-unmanaged.ts"
  needs_sudo  = true
}

# Hyprland renders on whichever card has the panel connected (a uwsm env
# block), not the iGPU.
script "t2-render-gpu" {
  description = "Hyprland renders on the GPU driving the panel (T2 Mac)"
  managed_by  = ".loadout/render-gpu.ts"
}
