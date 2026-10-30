# A libvirt VM for testing a new-machine setup end to end: plain Omarchy, no
# T2 hardware, plus the ssh key.
machine "omarchy-vm" {
  extends = [profile.omarchy]
  run     = ssh_key("id_ed25519")
}
