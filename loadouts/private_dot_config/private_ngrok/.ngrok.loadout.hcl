program "ngrok" {
  description = "ngrok tunnel"

  custom {
    installed_by = ".loadout/install-ngrok.ts"
  }

  path    = ["$HOME/.local/bin"]
  version = "ngrok version"
}
