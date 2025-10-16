local private_exists, private_config = pcall(require, "private") -- Load private config if it exists
local wezterm = require("wezterm") -- Load the wezterm API

local M = {}

M.setup = function(config)
	config.use_fancy_tab_bar = false
	config.tab_bar_at_bottom = true

	config.color_scheme = "Tokyo Night"
	if private_exists and private_config.color_scheme then
		config.color_scheme = private_config.color_scheme
	end

	config.font = wezterm.font_with_fallback({
		"Fira Code",
		"FiraCode Nerd Font Mono",
	})
	config.font_size = 12.0

	config.scrollback_lines = 10000

	config.underline_thickness = 1

	-- this assumes a dark background
	config.colors = {
		split = "#00cafc",
	}

	-- Slightly transparent and blurred background
	config.window_background_opacity = 0.9
	config.macos_window_background_blur = 30
end

return M
