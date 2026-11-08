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

program "t2-bluetooth-dkms" {
  description = "btbcm/hci_uart with KaiT2en's Apple fixes: Bluetooth LE devices show up and connect (DKMS)"
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
    program.t2-bluetooth-dkms,
    program.linux-apfs-rw-dkms,
    program.t2-fan-control,
    program.t2bce-audio-ucm,
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
  managed_by  = ".loadout/bcm-firmware.sh"
  needs_sudo  = true
  run_after   = [program.linux-apfs-rw-dkms, script.onepassword-cli]
}

# The KaiT2en kernel arguments Omarchy's installer writes for T2 Macs, kept
# against upstream migrations that rewrite /etc/limine-entry-tool.d/t2-mac.conf
# (#6562 once swapped pcie_ports=compat for pm_async=off). Next boot.
script "t2-kernel-args" {
  description = "pci=noaer pcie_ports=compat for fast resume (T2 Mac, linux-omarchy)"
  managed_by  = ".loadout/kernel-args.sh"
  needs_sudo  = true
}

# The real clock lives in the EC: t2smc reaches it (read and write), the
# legacy CMOS rtc only reads it. Writes it back at shutdown.
script "t2-boot-clock" {
  description = "keep the EC hardware clock set (T2 Mac)"
  managed_by  = ".loadout/boot-clock.sh"
  needs_sudo  = true
}

# The internal keyboard: Fn/Ctrl and Alt/Super swaps and the fnmode that
# keeps Fn+arrows working beside the touchbar. Two ways to rebuild the
# boot image; the machine picks.
script "t2-hid-apple-keyboard" {
  description = "internal keyboard fn/ctrl swap and fnmode"
  needs_sudo  = true

  variant "arch" {  # Limine (limine-mkinitcpio)
    managed_by = ".loadout/hid-apple-keyboard-arch.sh"
  }

  # dracut
  variant "fedora" {
    spare      = "no machine runs Fedora today"
    managed_by = ".loadout/hid-apple-keyboard.sh"
  }
}

# A sleep hook sends the backlight level back on resume; a udev rule puts it
# under systemd-backlight for reboots.
script "t2-gmux-backlight" {
  description = "screen brightness kept across suspend and reboots (T2 Mac)"
  managed_by  = ".loadout/gmux-backlight.sh"
  needs_sudo  = true
  run_after   = [script.omarchy-command-overrides]
}

# Hyprland renders on whichever card has the panel connected (a uwsm env
# block), not the iGPU.
script "t2-render-gpu" {
  description = "Hyprland renders on the GPU driving the panel (T2 Mac)"
  managed_by  = ".loadout/render-gpu.sh"
}
