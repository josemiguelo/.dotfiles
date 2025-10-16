local wezterm = require("wezterm") -- Load the wezterm API
local act = wezterm.action

local M = {}

M.setup = function(config)
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
end

return M
