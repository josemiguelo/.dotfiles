local wezterm = require("wezterm")
local setup_ui = require("ui").setup
local setup_tabs = require("tabs").setup
local setup_ssh = require("ssh").setup
local setup_switcher = require("switcher").setup

local config = wezterm.config_builder()

setup_ui(config)
setup_tabs(config)
setup_ssh(config)
setup_switcher(config)

config.default_prog = { "/bin/zsh", "--login" }

return config
