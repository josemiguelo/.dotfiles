# OpenAI's Codex CLI: a cask on macOS; on Omarchy it comes from mise, so it
# isn't mapped there.
program "codex" {
  description = "OpenAI Codex CLI"
  install_via = [brew-cask]
}
