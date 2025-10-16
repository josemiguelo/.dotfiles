local wezterm = require("wezterm")
local setup_ui = require("ui").setup
local setup_keymaps = require("keymaps").setup

local config = wezterm.config_builder()

setup_ui(config)
setup_keymaps(config)

return config
