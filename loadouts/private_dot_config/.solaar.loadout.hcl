program "solaar" {
  description = "Logitech device manager"
  install_via = [omarchy]
}

# Launched when wanted, not at every login.
script "solaar-no-autostart" {
  description = "remove solaar autostart entry"
  run         = "sudo rm -f /etc/xdg/autostart/solaar.desktop"
  check       = "test ! -f /etc/xdg/autostart/solaar.desktop"
  run_after   = [program.solaar]
}
