local wezterm = require("wezterm")
local act = wezterm.action
local utils = require("utils")

local M = {}

M.setup = function(config)
	wezterm.on("update-right-status", function(window, pane)
		window:set_right_status(" " .. window:active_workspace() .. " ")
	end)

	local plugin_url = "https://github.com/MLFlexer/smart_workspace_switcher.wezterm"
	local workspace_switcher = wezterm.plugin.require(plugin_url)

	if wezterm.target_triple:find("darwin") then
		workspace_switcher.zoxide_path = "/opt/homebrew/bin/zoxide"
	end

	workspace_switcher.apply_to_config(config)

	M.setup_keymaps(config, workspace_switcher)
end

M.setup_keymaps = function(config, workspace_switcher)
	local renamer = wezterm.action.PromptInputLine({
		description = "Enter new name for workspace",
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
			end
		end),
	})

	local killer = wezterm.action_callback(function(window)
		utils.kill_workspace(window:active_workspace())
	end)

	local fuzzy_matcher = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" })

	table.insert(config.keys, { key = "k", mods = "CTRL|ALT", action = killer })
	table.insert(config.keys, { key = "r", mods = "CTRL|ALT", action = renamer })
	table.insert(config.keys, { key = "t", mods = "CTRL|ALT", action = fuzzy_matcher })
	table.insert(config.keys, { key = "[", mods = "CTRL|ALT", action = act.SwitchWorkspaceRelative(1) })
	table.insert(config.keys, { key = "]", mods = "CTRL|ALT", action = act.SwitchWorkspaceRelative(-1) })
	table.insert(config.keys, { key = "s", mods = "CTRL|ALT", action = workspace_switcher.switch_workspace() })
	table.insert(config.keys, { key = "p", mods = "CTRL|ALT", action = workspace_switcher.switch_to_prev_workspace() })
end

return M
