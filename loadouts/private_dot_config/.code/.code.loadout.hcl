# VS Code: Omarchy's build (set up by ../.omarchy's omarchy-vscode).

program "code" {
  description = "Visual Studio Code"

  # Omarchy's own build ([omarchy] repo); omarchy-vscode adds its settings.
  via "omarchy" { pkg = "visual-studio-code-bin" }
}
