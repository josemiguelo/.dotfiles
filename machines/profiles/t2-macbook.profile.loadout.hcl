# Every MacBookPro16,1 (T2) running Omarchy: the T2 hardware fixes and what
# these machines run on top of Omarchy. Each install is its own machine
# (named by its hostname, so each keeps its own state file).
profile "t2-macbook" {
  extends = [profile.omarchy]

  via "omarchy" {
    install = [
      program.t2fanrd,
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

    variant(script.t2-hid-apple-keyboard, "arch"),
    script.t2-fan-curve, script.t2-fan-gpu-card, script.t2-boot-clock, script.t2-gmux-backlight,
    script.t2-render-gpu,
    variant(script.setup-libvirt, "arch"), script.ufw-libvirt,
    script.omarchy-sudoless-docker,
    args(script.omarchy-activity-monitor-size, "90%", "90%"),
    args(script.omarchy-scratchpad-opacity, "0.99"),
    script.solaar-no-autostart,
  ]
}
