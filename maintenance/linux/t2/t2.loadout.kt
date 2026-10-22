// T2 Macs (MacBookPro16,1): fan daemon and curve, the EC clock, the internal
// keyboard, the screen backlight and the GPU Hyprland renders on.
package loadouts

import loadout.dsl.*

/** The T2 fan daemon (arch-mact2), tracked so the curve's daemon is part of the loadout, not an installer side effect. */
val t2fanrd = program(
    name = "t2fanrd",
    description = "T2 Mac fan control daemon",
) {
    installVia(
        omarchy,
    )
}

/** The T2 Mac fixes: `run(T2.fanCurve)`. */
object T2 {
    /** /etc/t2fand.conf, which no package owns: this is the only record of the curve. */
    val fanCurve = script(
        name = "t2-fan-curve",
        description = "t2fanrd fan curve in /etc/t2fand.conf",
    ) {
        managedBy("fan-curve.sh")
        needsSudo()
        runAfter(t2fanrd)
    }

    /** t2fanrd reads card0 only; this makes card0 the AMD dGPU (simpledrm dropped, the sensor's GPU first in the initramfs). Next boot. */
    val fanGpuCard = script(
        name = "t2-fan-gpu-card",
        description = "the GPU with a temperature sensor as card0, where t2fanrd reads it",
    ) {
        managedBy("fan-gpu-card.sh")
        needsSudo()
        runAfter(t2fanrd)
    }

    /** The real clock lives in the EC, reachable only through the ACPI TAD's _SRT; sets it and keeps it true at shutdown. */
    val bootClock = script(
        name = "t2-boot-clock",
        description = "keep the EC hardware clock set (T2 Mac)",
    ) {
        managedBy("boot-clock.sh")
        needsSudo()
    }

    // The internal keyboard: Fn/Ctrl and Alt/Super swaps and the fnmode that
    // keeps Fn+arrows working beside the touchbar. Two ways to rebuild the
    // boot image; the machine picks.
    val hidAppleKeyboard = script(
        name = "t2-hid-apple-keyboard",
        description = "internal keyboard fn/ctrl swap and fnmode",
    ) {
        needsSudo()
        variant(name = "arch") { managedBy("hid-apple-keyboard-arch.sh") } // Limine (limine-mkinitcpio)
        // dracut
        variant(name = "fedora") {
            spare(reason = "no machine runs Fedora today")
            managedBy("hid-apple-keyboard.sh")
        }
    }

    /** A sleep hook sends the backlight level back on resume; a udev rule puts it under systemd-backlight for reboots. */
    val gmuxBacklight = script(
        name = "t2-gmux-backlight",
        description = "screen brightness kept across suspend and reboots (T2 Mac)",
    ) {
        managedBy("gmux-backlight.sh")
        needsSudo()
        runAfter(Overrides.commands)
    }

    /** Hyprland renders on whichever card has the panel connected (a uwsm env block), not the iGPU. */
    val renderGpu = script(
        name = "t2-render-gpu",
        description = "Hyprland renders on the GPU driving the panel (T2 Mac)",
    ) {
        managedBy("render-gpu.sh")
    }
}
