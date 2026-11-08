# MacBookPro16,1 (T2) running Omarchy.
machine "t2-macbook-omarchy" {
  extends = [profile.t2-macbook]

  # Omarchy ISO testing, also on fake hardware (omarchy-iso-test --fake-pci).
  via "omarchy" {
    install = [local.omarchy_iso_test_deps]
  }

  # The name this machine has synced under since Intentional's sync began.
  run = [args(script.intentional-sync, "t2-macbook")]
}
