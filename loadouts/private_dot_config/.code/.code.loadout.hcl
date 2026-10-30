# VS Code: Microsoft's repo on Fedora (.loadout/vscode.repo), Omarchy's build
# on Omarchy (set up by ../.omarchy's omarchy-vscode).

program "code" {
  description = "Visual Studio Code"

  via "dnf-repo" {
    params = { repofile = file(".loadout/vscode.repo") }
  }

  # Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
  via "omarchy" { pkg = "visual-studio-code-bin" }
}
