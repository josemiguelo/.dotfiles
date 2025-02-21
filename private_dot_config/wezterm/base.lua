local wezterm = require("wezterm")

local act = wezterm.action
local config = wezterm.config_builder()

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.color_scheme = "Tokyo Night"
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

config.keys = {
	{
		key = "E",
		mods = "CTRL|SHIFT|ALT",
		action = act.PromptInputLine({
			description = "Enter new name for tab",
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:active_tab():set_title(line)
				end
			end),
		}),
	},
}

return config
