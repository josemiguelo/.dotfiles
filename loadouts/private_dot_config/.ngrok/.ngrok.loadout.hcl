program "ngrok" {
  description = "ngrok tunnel"

  custom {
    installed_by = ".loadout/install-ngrok.sh"
  }

  path    = ["$HOME/.local/bin"]
  version = "ngrok version"
}
