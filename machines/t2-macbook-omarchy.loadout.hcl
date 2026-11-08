# MacBookPro16,1 (T2) running Omarchy.
machine "t2-macbook-omarchy" {
  extends = [profile.t2-macbook]

  # Omarchy ISO testing, also on fake hardware (omarchy-iso-test --fake-pci).
  via "omarchy" {
    install = [local.omarchy_iso_test_deps]
  }

  run = [
    # The name this machine has synced under since Intentional's sync began.
    args(script.intentional-sync, "t2-macbook"),
    # The KaiT2en -> Omarchy work: its repos, then the rest (docs/t2-macbook.md).
    args(script.bare-repos,
      "t2-arch-packages",
      "omarchy",
      "omarchy-iso",
    ),
    script.kait2en-dev,
  ]
}
