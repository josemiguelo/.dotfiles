program "solaar" {
  description = "Logitech device manager"

  via "dnf" {
    spare = "for a Fedora machine; the fedora profile doesn't install solaar"
  }

  install_via = [omarchy]
}

# Launched when wanted, not at every login.
script "solaar-no-autostart" {
  description = "remove solaar autostart entry"
  run         = "sudo rm -f /etc/xdg/autostart/solaar.desktop"
  check       = "test ! -f /etc/xdg/autostart/solaar.desktop"
  run_after   = [program.solaar]
}
