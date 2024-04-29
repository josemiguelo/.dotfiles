local wezterm = require("wezterm")

local act = wezterm.action
local config = wezterm.config_builder()

config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true

config.color_scheme = "Tokyo Night"
config.font = wezterm.font("FiraCode Nerd Font Mono")
config.font_size = 9.0

config.scrollback_lines = 10000

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
