# MacBookPro16,1 (T2) running Omarchy.
machine "t2-macbook-omarchy" {
  extends = [profile.t2-macbook]

  # The name this machine has synced under since Intentional's sync began.
  run = [args(script.intentional-sync, "t2-macbook")]
}
