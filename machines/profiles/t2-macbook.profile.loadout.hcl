# Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
# these machines run on top of Omarchy. Each install is its own machine
# (named by its hostname, so each keeps its own state file).
profile "t2-macbook" {
  extends = [profile.omarchy]

  via "omarchy" {
    install = [
      local.kait2en, # KaiT2en's T2 drivers on linux-omarchy, and their repo
      local.arch_virtualization,
      program.solaar,
      program.rocm-smi-lib, # btop's stats for the Radeon Pro 5300M/5500M
    ]
  }

  run = [
    ssh_key("id_ed25519"),
    # The GitHub keys (by title) that get a shell here.
    args(script.omarchy-sshd,
      "t2-macbook-omarchy",
      "t2-macbook-omarchy-2",
      "omarchy-vm",
      "omalauncher-galaxy-a56",
      "work-mac",
    ),

    script.t2-omarchy-channel,
    variant(script.t2-hid-apple-keyboard, "arch"),
    script.t2-kernel-args, script.remove-t2-boot-clock, script.t2-gmux-backlight,
    script.t2-bcm-firmware,
    script.t2-render-gpu,
    script.t2-ibridge-unmanaged,
    args(script.t2-charge-limit, "85"),
    script.t2-smc-gaugingd,
    script.t2-force-click-daemon,
    script.t2-post-update-check,
    variant(script.setup-libvirt, "arch"), script.ufw-libvirt,
    script.omarchy-sudoless-docker,
    args(script.omarchy-activity-monitor-size, "90%", "90%"),
    args(script.omarchy-scratchpad-opacity, "0.99"),
    script.solaar-no-autostart,
  ]
}
